module Twig
  class Environment
    # @param [::Twig::Loader::Base] loader
    def initialize(loader)
      @loader = loader
      @extension_set = ExtensionSet.new

      add_extension(Extension::CoreExtension.new)
    end

    def render(name)
      loader.get_source_context(name).code
    end

    # @param [Extension::Extension] extension
    def add_extension(extension)
      @extension_set.add(extension)
    end

    # @return [Array]
    def operators
      @extension_set.operators
    end

    # @return [Filter]
    def filter(name)
      @extension_set.filter(name)
    end

    private

    # @return [Twig::Loader::Base]
    def loader
      @loader
    end
  end
end
