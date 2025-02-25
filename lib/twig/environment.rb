# frozen_string_literal: true

module Twig
  class Environment
    # @return [Cache::Base]
    attr_reader :cache, :charset

    # @param [::Twig::Loader::Base] loader
    def initialize(loader, options = {})
      @loader = loader
      @extension_set = ExtensionSet.new
      @options = {
        cache: false,
        debug: false,
        charset: 'UTF-8',
        auto_escape: 'html',
        auto_reload: nil,
        allow_helper_methods: false,
      }.merge(options)

      @auto_reload = options[:auto_reload].nil? ? options[:debug] : options[:auto_reload]
      @charset = options[:charset]

      self.cache = @options[:cache]

      add_extension(Extension::Core.new)
      add_extension(Extension::Escaper.new(options[:auto_escape]))
    end

    def template_class(name)
      key = loader.get_cache_key(name)

      "Compiled::Template_#{::Digest::SHA256.hexdigest(key)}"
    end

    # @return [Twig::Template]
    def load_template(name, **)
      class_name = template_class(name)
      cache_key = cache.generate_key(name, class_name)

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

      Twig.const_get(template_class(name)).
        new(self, **)
    end

    def render(name)
      loader.get_source_context(name).code
    end

    def render_ruby(name)
      compile_source(
        loader.get_source_context(name)
      )
    end

    def extension(name)
      @extension_set.extensions[name]
    end

    # @param [Extension::Base] extension
    def add_extension(extension)
      @extension_set.add(extension)
    end

    # @return [Array]
    def operators
      @extension_set.operators
    end

    # @return [TwigFilter, nil]
    def filter(name)
      @extension_set.filter(name)
    end

    # @return [TwigFunction, nil]
    def function(name)
      @extension_set.function(name)
    end

    # @return [TwigTest, nil]
    def test(name)
      @extension_set.test(name)
    end

    # @return [TokenParser::Base, nil]
    def token_parser(name)
      @extension_set.token_parser(name)
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

    private

    # @return [Twig::Loader::Base]
    attr_reader :loader

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
