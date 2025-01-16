# frozen_string_literal: true

module Twig
  class Environment
    # @param [::Twig::Loader::Base] loader
    def initialize(loader)
      @loader = loader
      @extension_set = ExtensionSet.new

      add_extension(Extension::Core.new)
    end

    def template_class(name)
      key = loader.get_cache_key(name)

      "Compiled::Template_#{::Digest::SHA256.hexdigest(key)}"
    end

    # @return [Twig::Template]
    def load_template(name, **)
      class_name = template_class(name)

      unless Twig.const_defined?(class_name)
        code = render_ruby(name)
        Twig.module_eval(code)
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

    # @return [TwigFilter]
    def filter(name)
      @extension_set.filter(name)
    end

    # @return [TokenParser::Base]
    def token_parser(name)
      @extension_set.token_parser(name)
    end

    # @return [Boolean]
    def helper_method?(name)
      @extension_set.helper_methods.include?(name)
    end

    # @param [Source] source
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
