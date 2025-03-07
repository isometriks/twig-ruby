# frozen_string_literal: true

module Twig
  module TokenParser
    class Extends < TokenParser::Base
      def parse(token)
        stream = parser.stream

        if parser.peek_block_stack
          raise Error::Syntax.new('Cannot use "extend" in a block', token.lineno, stream.source)
          # elsif parser.main_scope? @todo
        end

        parser.parent = parser.expression_parser.parse_expression
        stream.expect(Token::BLOCK_END_TYPE)

        Node::Empty.new(token.lineno)
      end

      def tag
        'extends'
      end
    end
  end
end
