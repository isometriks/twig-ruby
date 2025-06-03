# frozen_string_literal: true

require_relative 'infix/parses_arguments'

module Twig
  module ExpressionParser
    class Base
      def to_s
        "Some kinda EP: #{name}"
      end

      def name
        raise NotImplementedError
      end

      def precedence
        raise NotImplementedError
      end

      # @return [Symbol]
      def type
        raise NotImplementedError
      end

      def aliases
        []
      end
    end
  end
end
