# frozen_string_literal: true

module Twig
  module ExpressionParser
    class InfixExpressionParser < ExpressionParser::Base
      LEFT = 'left'
      RIGHT = 'right'

      # @param [Parser] parser
      # @param [Node::Expression::Base] left
      # @param [Token] token
      # @return [Node::Expression::Base]
      def parse(parser, left, token)
        raise NotImplementedError
      end

      def associativity
        raise NotImplementedError
      end

      def left?
        associativity == LEFT
      end

      def right?
        associativity == RIGHT
      end

      def type
        :infix
      end
    end
  end
end
