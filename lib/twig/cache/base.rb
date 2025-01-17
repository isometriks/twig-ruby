# frozen_string_literal: true

module Twig
  module Cache
    class Base
      # @param [String] name
      # @param [String] class_name
      def generate_key(name, class_name)
        raise NotImplementedError
      end

      # @param [String] key
      # @param [String] content
      def write(key, content)
        raise NotImplementedError
      end

      # @param [String] key
      # @return [Boolean]
      def load(key)
        raise NotImplementedError
      end

      # @param [String] key
      # @return [Integer]
      def timestamp(key)
        raise NotImplementedError
      end
    end
  end
end
