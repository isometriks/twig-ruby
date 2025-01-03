module Twig
  class Environment
    # @param [::Twig::Loader::Base] loader
    def initialize(loader)
      @loader = loader
    end

    def render(name)
      loader.get_source_context(name).code
    end

      # @return [Twig::Loader::Base]
    private def loader
      @loader
    end
  end
end
