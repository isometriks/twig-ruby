# frozen_string_literal: true

module Twig
  module Loader
    class Array < Loader::Base
      # @param [Hash<String>] templates
      def initialize(templates)
        super()

        @templates = templates.transform_keys { |name| normalize_name(name) }
      end

      def get_source_context(name)
        name = normalize_name(name)

        unless @templates[name]
          raise Error::Loader, "Template \"#{name}\" is not defined."
        end

        ::Twig::Source.new(@templates[name], name)
      end

      def exists?(name)
        name = normalize_name(name)

        @templates.key?(name)
      end

      def get_cache_key(name)
        name = normalize_name(name)

        unless @templates[name]
          raise Error::Loader, "Template \"#{name}\" is not defined."
        end

        "#{name}:#{@templates[name]}"
      end

      def fresh?(name, time)
        name = normalize_name(name)

        unless @templates[name]
          raise Error::Loader, "Template \"#{name}\" is not defined."
        end

        true
      end

      private

      def normalize_name(name)
        name.to_s
      end
    end
  end
end
