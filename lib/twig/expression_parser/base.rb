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

      # The operator tokens the lexer recognizes for this parser and the
      # names it is looked up by: its name and aliases, unless it handles
      # no operator at all.
      #
      # @return [Array<String>]
      def operator_tokens
        [name, *aliases]
      end
    end
  end
end
