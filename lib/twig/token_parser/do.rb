# frozen_string_literal: true

module Twig
  module TokenParser
    class Do < TokenParser::Base
      def parse(token)
        expr = parser.expression_parser.parse_expression

        parser.stream.expect(Token::BLOCK_END_TYPE)

        Node::Do.new(expr, token.lineno)
      end

      def tag
        'do'
      end
    end
  end
end
