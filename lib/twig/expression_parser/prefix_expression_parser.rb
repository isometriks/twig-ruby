# frozen_string_literal: true

module Twig
  module ExpressionParser
    class PrefixExpressionParser < ExpressionParser::Base
      # @param [Parser] parser
      # @param [Token] token
      # @return [Node::Expression::Base]
      def parse(parser, token)
        raise NotImplementedError
      end

      def type
        :prefix
      end
    end
  end
end
