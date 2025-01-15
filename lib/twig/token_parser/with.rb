# frozen_string_literal: true

module Twig
  module TokenParser
    class With < TokenParser::Base
      def parse(token)
        stream = parser.stream

        variables = nil

        unless stream.test(Token::BLOCK_END_TYPE)
          variables = parser.expression_parser.parse_expression
          !!stream.next_if(Token::NAME_TYPE, 'only')
        end

        stream.expect(Token::BLOCK_END_TYPE)
        parser.subparse(decide_with_end, drop_needle: true)
        stream.expect(Token::BLOCK_END_TYPE)

        raise [variables].inspect
      end

      def tag
        'with'
      end

      private

      def decide_with_end
        ->(token) { token.test('endwith') }
      end
    end
  end
end
