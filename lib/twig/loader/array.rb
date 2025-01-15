# frozen_string_literal: true

module Twig
  module Loader
    class Array < Base
      # @param [Hash<String>] templates
      def initialize(templates)
        @templates = templates.transform_keys(&:to_sym)
      end

      def get_source_context(name)
        raise "LoaderError: Template #{name} is not defined" unless @templates[name.to_sym]

        ::Twig::Source.new(@templates[name.to_sym], name)
      end

      def exists?(name)
        @template.key?(name)
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
