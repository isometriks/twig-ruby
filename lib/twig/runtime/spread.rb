# frozen_string_literal: true

module Twig
  module Runtime
    class Spread
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def array?
        value.is_a?(Array) || value.is_a?(Range)
      end

      def hash?
        value.is_a?(Hash)
      end
    end
  end
end
