# frozen_string_literal: true

module Twig
  class Environment
    # Compiled template classes are constants shared by every environment, and
    # a recompile replaces them, so loads are serialised across environments.
    LOAD_LOCK = Monitor.new
    private_constant :LOAD_LOCK

    # @return [Cache::Base]
    attr_reader :cache, :charset

    # @return [Twig::Loader::Base]
    attr_reader :loader

    # @param [::Twig::Loader::Base] loader
    def initialize(loader, options = {})
      @loader = loader
      @extension_set = ExtensionSet.new
      @options = {
        cache: false,
        debug: false,
        charset: 'UTF-8',
        strict_variables: false,
        autoescape: :html,
        auto_reload: nil,
        allow_helper_methods: false,
      }.merge(options)

      @auto_reload = @options[:auto_reload].nil? ? @options[:debug] : @options[:auto_reload]
      @charset = @options[:charset]
      @strict_variables = @options[:strict_variables]

      self.cache = @options[:cache]

      @loaded_templates = {}
      @loaded_at = {}
      @globals = {}
      @runtimes = {}
      @runtime_loaders = []
      @default_runtime_loader = RuntimeLoader::Factory.new({
        Runtime::Escaper => -> { Runtime::Escaper.new(@charset) },
      })

      add_extension(Extension::Core.new)
      add_extension(Extension::Escaper.new(@options[:autoescape]))
    end

    def template_class(name, index = nil)
      key = loader.get_cache_key(name) + options_hash

      "Compiled::Template_#{::Digest::SHA256.hexdigest(key)}#{"___#{index}" if index}"
    end

    # A digest of the gem's own Ruby source. Twig::VERSION only changes with a
    # release, but the shape of compiled templates changes with the compiler,
    # so a gem used from a path or a git branch must not load cache entries
    # an earlier checkout of it compiled.
    #
    # @return [String]
    def self.source_signature
      @source_signature ||= begin
        lib = File.expand_path('..', __dir__)
        digest = ::Digest::SHA256.new

        Dir.glob('**/*.rb', base: lib).sort.each do |file|
          digest << file << "\0" << File.binread(File.join(lib, file))
        end

        digest.hexdigest
      end
    end

    # @param [String, Twig::TemplateWrapper] name
    # @return [Twig::TemplateWrapper]
    def load(name)
      if name.is_a?(Twig::TemplateWrapper)
        return name
      end

      cls = template_class(name)
      TemplateWrapper.new(
        self,
        load_template(cls, name)
      )
    end

    # @param [String, Twig::TemplateWrapper, Array<String>] name
    def resolve_template(names)
      unless names.is_a?(Array)
        return load(names)
      end

      count = names.length

      names.each do |name|
        if name.is_a?(Twig::TemplateWrapper)
          return name
        end

        unless count == 1 || loader.exists?(name)
          next
        end

        return load(name)
      end

      raise Error::Loader, "Unable to find one of the following templates: \"#{names.join('", "')}\"."
    end

    # @param [String] cls The class name to load
    # @param [String] name The template name
    # @param [Integer, nil] index Index for embedded templates
    # @return [Twig::Template]
    def load_template(cls, name, index: nil)
      # Template#load passes its own class name, which starts with Twig::
      main_cls = cls.delete_prefix('Twig::')
      cls = index ? "#{main_cls}___#{index}" : main_cls

      # Embedded templates are compiled with their parent, whose own load has
      # just brought them up to date
      if !index.nil? && Twig.const_defined?(cls)
        return @loaded_templates[cls] = Twig.const_get(cls).new(self)
      end

      if !@auto_reload && @loaded_templates.key?(cls)
        return @loaded_templates[cls]
      end

      LOAD_LOCK.synchronize do
        # Freshness is judged by when this process evaluated the template, not
        # by the cache entry: another process sharing the cache may have
        # recompiled the template since, leaving an entry newer than the edit
        # while this process still holds the code from before it.
        if @loaded_templates.key?(cls) && @loaded_at.key?(main_cls)
          return @loaded_templates[cls] unless @auto_reload

          # A new instance each time, since the constructor loads the templates
          # this one uses as traits and they get no freshness check otherwise.
          # It comes from the class this environment loaded, not the constant,
          # which another environment's compile may have replaced since.
          if template_fresh?(name, @loaded_at[main_cls])
            return @loaded_templates[cls] = @loaded_templates[cls].class.new(self)
          end
        end

        cache_key = cache.generate_key(name, main_cls)
        cached_at = cache.timestamp(cache_key)

        if !@auto_reload || template_fresh?(name, cached_at)
          remove_template_class(main_cls)

          # Whether the class is defined now says if the entry loaded, since
          # PHP's load returns nothing and a cache ported from it may too
          @cache.load(cache_key)

          if Twig.const_defined?(cls)
            @loaded_at[main_cls] = cached_at

            return @loaded_templates[cls] = Twig.const_get(cls).new(self)
          end
        end

        # No caches have fresh template at this point, so write it now. The
        # entry is stamped with the moment before the source was read, so a
        # save made while compiling still looks newer than it. The clock is
        # one that time travel in tests leaves alone, so an entry is never
        # stamped in the future.
        compiled_at = Process.clock_gettime(Process::CLOCK_REALTIME, :second)
        code = render_ruby(name)
        write_cache(cache_key, code, compiled_at)

        # Evaluate what was just compiled rather than loading the cache entry
        # back, which another process may have replaced in the meantime. This
        # also brings an already defined class up to date when nothing is
        # cached.
        remove_template_class(main_cls)
        Twig.module_eval(code, cache_key.empty? ? "(twig #{name})" : cache_key, 1)
        @loaded_at[main_cls] = compiled_at

        @loaded_templates[cls] = Twig.const_get(cls).new(self)
      end
    end

    # @return [Twig::Template]
    def create_template(template, name = nil)
      hash = ::Digest::SHA256.hexdigest(template)
      name = if name.nil?
               "__string_template__#{hash}"
             else
               "#{name} (string template #{hash})"
             end

      chain_loader = Loader::Chain.new([
        Loader::Hash.new({ name => template }),
        current = loader,
      ])

      @loader = chain_loader

      cls = template_class(name)
      TemplateWrapper.new(self, load_template(cls, name))
    ensure
      @loader = current
    end

    def extension(name)
      extension_set.get(name)
    end

    def extension?(name)
      extension_set.has?(name)
    end

    # @param [Extension::Base] extension
    def add_extension(extension)
      extension_set.add(extension)
      @options_hash = nil
    end

    def runtime(klass)
      return runtimes[klass] if runtimes.key?(klass)

      runtime_loaders.each do |loader|
        if (runtime = loader.load(klass))
          return runtimes[klass] = runtime
        end
      end

      if (runtime = default_runtime_loader.load(klass))
        return runtimes[klass] = runtime
      end

      raise Error::Runtime, "Unable to load the \"#{klass}\" runtime."
    end

    # @param [RuntimeLoader::Base] loader
    def add_runtime_loader(loader)
      runtime_loaders << loader
    end

    # @return [ExpressionParser::ExpressionParsers]
    def expression_parsers
      extension_set.expression_parsers
    end

    # @return [TwigFilter, nil]
    def filter(name)
      extension_set.filter(name)
    end

    # @return [TwigFunction, nil]
    def function(name)
      extension_set.function(name)
    end

    # @return [TwigTest, nil]
    def test(name)
      extension_set.test(name)
    end

    # @return [TokenParser::Base, nil]
    def token_parser(name)
      extension_set.token_parser(name)
    end

    # @return [Array<NodeVisitor::Base>]
    def node_visitors
      extension_set.node_visitors
    end

    def add_global(name, value)
      @globals[name] = value
    end

    def globals
      @resolved_globals ||= extension_set.globals.merge(@globals)
    end

    # @param [Source] source
    # @return [TokenStream]
    def tokenize(source)
      lexer.tokenize(source)
    end

    # @param [TokenStream] stream
    def parse(stream)
      parser.parse(stream)
    end

    # @param [Node::Base] node
    def compile(node)
      compiler.compile(node).source
    end

    # @param [Source] source
    def compile_source(source)
      compile(parse(tokenize(source)))
    rescue Error::Base => e
      e.source_context = source
      raise e
    end

    # @return [String]
    def load_and_compile(name)
      source = loader.get_source_context(name)
      compile_source(source)
    end

    # @param [String] name
    # @param [Integer] time
    def template_fresh?(name, time)
      # @todo check extension set last modified
      loader.fresh?(name, time)
    end

    def cache=(cache)
      @cache = if cache.is_a?(String)
                 Cache::Filesystem.new(cache)
               elsif cache == false
                 Cache::Nil.new
               elsif cache.class < Cache::Base
                 cache
               else
                 raise "Cache must be string, false, or implement Twig::Cache::Base, got #{cache.inspect}"
               end
    end

    # @return [Boolean]
    def allow_helper_methods?
      @options[:allow_helper_methods]
    end

    def debug?
      @options[:debug]
    end

    def strict_variables?
      @strict_variables
    end

    private

    # @return [ExtensionSet]
    attr_reader :extension_set

    # @return [RuntimeLoader::Base]
    attr_reader :default_runtime_loader

    # @return [Array<RuntimeLoader::Base>]
    attr_reader :runtime_loaders

    # @return [Hash{String => Object}]
    attr_reader :runtimes

    # Everything besides the template that changes the code it compiles to,
    # so environments with different options never share a compiled class or
    # a cache entry
    #
    # @return [String]
    def options_hash
      @options_hash ||= [
        extension_set.signature,
        *RUBY_VERSION.split('.').first(2),
        VERSION,
        self.class.source_signature,
        debug? ? 1 : 0,
        strict_variables? ? 1 : 0,
        allow_helper_methods? ? 1 : 0,
        autoescape_signature,
      ].join(':')
    end

    # The autoescape option picks each template's escaping when it compiles.
    # A lambda is named by where it's defined, since its inspect holds an
    # address that changes with every process and no entry would be reused.
    #
    # @return [String]
    def autoescape_signature
      strategy = @options[:autoescape]

      if strategy.is_a?(Proc)
        strategy.source_location.to_a.join(':')
      else
        strategy.inspect
      end
    end

    def render_ruby(name)
      compile_source(
        loader.get_source_context(name)
      )
    end

    # A cache written for PHP's two-argument write still works, but its
    # entries are stamped when they're written instead
    #
    # @param [String] key
    # @param [String] code
    # @param [Integer] mtime
    def write_cache(key, code, mtime)
      if @cache.method(:write).parameters.any? { |type, param| type == :keyrest || param == :mtime }
        @cache.write(key, code, mtime:)
      else
        @cache.write(key, code)
      end
    end

    # Loading or evaluating a template's code reopens its class when it is
    # already defined, so methods the new source no longer has (a deleted
    # macro, the get_parent of a removed extends) would survive the recompile.
    # Only the main class is removed: embedded templates get a new random index
    # on every compile, and a render running in another thread may still be
    # looking theirs up. Instances made from the old class keep working.
    #
    # @param [String] main_cls
    def remove_template_class(main_cls)
      base = main_cls.delete_prefix('Compiled::')

      Twig::Compiled.send(:remove_const, base) if Twig::Compiled.const_defined?(base, false)
    end

    def lexer
      @lexer ||= Lexer.new(self)
    end

    def parser
      @parser ||= Parser.new(self)
    end

    def compiler
      @compiler ||= Compiler.new(self)
    end
  end
end
