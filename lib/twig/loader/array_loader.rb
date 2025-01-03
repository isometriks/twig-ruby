module Twig
  module Loader
    class ArrayLoader < Base
      # @param [Hash<String>] templates
      def initialize(templates)
        @templates = templates.transform_keys(&:to_s)
      end

      def get_source_context(name)
        raise "LoaderError: Template #{name} is not defined" unless @templates[name]

        ::Twig::Source.new(@templates[name], name)
      end

      def exists?(name)
        @template.has_key?(name)
      end

      def get_cache_key(name)
        raise "LoaderError: Template #{name} is not defined" unless @templates[name]

        "#{name}:#{@templates[name]}"
      end

      def fresh?(name, time)
        raise "LoaderError: Template #{name} is not defined" unless @templates[name]

        true
      end
    end
  end
end
