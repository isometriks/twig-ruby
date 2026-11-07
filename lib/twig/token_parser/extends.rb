# frozen_string_literal: true

module Twig
  module TokenParser
    class Extends < TokenParser::Base
      def parse(token)
        stream = parser.stream
        # where the tag can be used is checked by NodeVisitor::Correctness
        parser.set_parent(parser.parse_expression, throw_on_multiple: false)
        stream.expect(Token::BLOCK_END_TYPE)

        Node::Config.new(token.lineno)
      end

      def tag
        'extends'
      end
    end
  end
end
