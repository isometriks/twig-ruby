# frozen_string_literal: true

module Twig
  class Environment
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
      key = loader.get_cache_key(name)

      "Compiled::Template_#{::Digest::SHA256.hexdigest(key)}#{"__#{index}" if index}"
    end

    # @param [String, Twig::TemplateWrapper] name
    # @return [Twig::TemplateWrapper]
    def load(name, **)
      if name.is_a?(Twig::TemplateWrapper)
        return name
      end

      TemplateWrapper.new(
        self,
        load_template(name, **)
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

    # @return [Twig::Template]
    def load_template(name, index: nil, **)
      class_name = template_class(name, index)
      cache_key = cache.generate_key(name, class_name)

      # @todo this isn't right
      attempt_cache = !@auto_reload && template_fresh?(name, cache.timestamp(cache_key))

      if attempt_cache
        @cache.load(cache_key)
      end

      # Cache didn't load a class or we should load fresh
      unless attempt_cache && Twig.const_defined?(class_name)
        code = render_ruby(name)

        # File cache loader won't rely on eval
        @cache.write(cache_key, code)
        @cache.load(cache_key)

        # Finally just eval the generated code if cache does
        # create the class
        Twig.module_eval(code) unless Twig.const_defined?(class_name)
      end

      Twig.const_get(class_name).new(self)
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
        Loader::Array.new({ name => template }),
        current = loader,
      ])

      @loader = chain_loader

      TemplateWrapper.new(self, load_template(name))
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

    def render_ruby(name)
      compile_source(
        loader.get_source_context(name)
      )
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
