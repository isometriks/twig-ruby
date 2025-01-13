module Twig
  module TokenParser
    class Yield < TokenParser::Base
      def parse(token)
        stream = parser.stream
        lineno = token.lineno
        expr = parser.expression_parser.parse_expression

        name = stream.expect(Token::YIELD_TYPE).value

        stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(decide_yield_end, drop_needle: true)
        stream.expect(Token::BLOCK_END_TYPE)

        Node::Yield.new(expr, body, name, lineno)
      end

      def tag
        'yield'
      end

      private

      def decide_yield_end
        -> (token) { token.test('endyield') }
      end
    end
  end
end
