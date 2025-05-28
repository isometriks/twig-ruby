# frozen_string_literal: true

module Twig
  module TokenParser
    # Creates a nested scope
    class With < Base
      def parse(token)
        stream = parser.stream

        variables = nil
        only = false

        unless stream.test(Token::BLOCK_END_TYPE)
          variables = parser.expression_parser.parse_expression
          only = !stream.next_if(Token::NAME_TYPE, 'only').nil?
        end

        stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(method(:decide_with_end), drop_needle: true)
        stream.expect(Token::BLOCK_END_TYPE)

        Node::With.new(body, variables, only, token.lineno)
      end

      def tag
        'with'
      end

      private

      def decide_with_end(token)
        token.test('endwith')
      end
    end
  end
end
