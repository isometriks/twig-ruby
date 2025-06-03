# frozen_string_literal: true

module Twig
  module TokenParser
    class Include < TokenParser::Base
      def parse(token)
        expr = parser.parse_expression
        variables, only, ignore_missing = parse_arguments

        Node::Include.new(
          expr,
          variables,
          only,
          ignore_missing,
          token.lineno
        )
      end

      def tag
        'include'
      end

      private

      def parse_arguments
        stream = parser.stream
        ignore_missing = false

        if stream.next_if(Token::NAME_TYPE, 'ignore')
          stream.expect(Token::NAME_TYPE, 'missing')

          ignore_missing = true
        end

        variables = nil
        if stream.next_if(Token::NAME_TYPE, 'with')
          variables = parser.parse_expression
        end

        only = false
        if stream.next_if(Token::NAME_TYPE, 'only')
          only = true
        end

        stream.expect(Token::BLOCK_END_TYPE)

        [variables, only, ignore_missing]
      end
    end
  end
end
