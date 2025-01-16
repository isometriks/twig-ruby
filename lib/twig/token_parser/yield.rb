# frozen_string_literal: true

module Twig
  module TokenParser
    class Yield < TokenParser::Base
      def parse(token)
        stream = parser.stream
        lineno = token.lineno
        expr = parser.expression_parser.parse_expression
        arguments = []

        stream.expect(Token::NAME_TYPE, 'do')

        if stream.next_if(Token::PUNCTUATION_TYPE, '|')
          until stream.test(Token::PUNCTUATION_TYPE, '|')
            unless arguments.empty?
              stream.expect(Token::PUNCTUATION_TYPE, ',', 'Arguments must be separated by a comma')
            end

            arguments.push(stream.expect(Token::NAME_TYPE).value)
          end

          stream.expect(Token::PUNCTUATION_TYPE, '|')
        end

        stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(decide_yield_end, drop_needle: true)
        stream.expect(Token::BLOCK_END_TYPE)

        Node::Yield.new(expr, body, arguments, lineno)
      end

      def tag
        'yield'
      end

      private

      def decide_yield_end
        ->(token) { token.test('endyield') }
      end
    end
  end
end
