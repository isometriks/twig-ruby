# frozen_string_literal: true

module Twig
  module TokenParser
    class AutoEscape < TokenParser::Base
      def parse(token)
        lineno = token.lineno
        stream = parser.stream

        if stream.test(Token::BLOCK_END_TYPE)
          value = :html
        else
          expr = parser.expression_parser.parse_expression

          unless expr.is_a?(Node::Expression::Constant)
            raise Error::Syntax.new(
              'An escaping strategy must be a string or false.',
              stream.current.lineno,
              stream.source
            )
          end

          value = expr.attributes[:value]
          value = value.to_sym if value.is_a?(String)
        end

        stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(method(:decide_block_end), drop_needle: true)
        stream.expect(Token::BLOCK_END_TYPE)

        Node::AutoEscape.new(value, body, lineno)
      end

      def tag
        'autoescape'
      end

      private

      def decide_block_end(token)
        token.test('endautoescape')
      end
    end
  end
end
