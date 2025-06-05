# frozen_string_literal: true

module Twig
  module Loader
    class Array < Loader::Base
      # @param [Hash<String>] templates
      def initialize(templates)
        super()

        @templates = templates.transform_keys(&:to_sym)
      end

      def get_source_context(name)
        name = name.to_sym
        unless @templates[name]
          raise Error::Loader, "Template \"#{name}\" is not defined."
        end

        ::Twig::Source.new(@templates[name], name)
      end

      def exists?(name)
        @templates.key?(name.to_sym)
      end

      def get_cache_key(name)
        name = name.to_sym
        unless @templates[name]
          raise Error::Loader, "Template \"#{name}\" is not defined."
        end

        "#{name}:#{@templates[name]}"
      end

      def fresh?(name, time)
        name = name.to_sym
        unless @templates[name]
          raise Error::Loader, "Template \"#{name}\" is not defined."
        end

        true
      end
    end
  end
end
