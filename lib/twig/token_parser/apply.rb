# frozen_string_literal: true

module Twig
  module TokenParser
    # Applies filters on a section of a template.
    #
    # {% apply upper %}
    #   This text becomes uppercase
    # {% endapply %}
    class Apply < Base
      def parse(token)
        lineno = token.lineno
        ref = Node::Expression::Variable::Local.new(nil, lineno)
        filter = parser.expression_parser.parse_filter_expression_raw(ref)

        parser.stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(decide_apply_end, drop_needle: true)
        parser.stream.expect(Token::BLOCK_END_TYPE)

        Node::Nodes.new({
          0 => Node::Set.new(true, ref, body, lineno),
          1 => Node::Print.new(filter, lineno),
        }, lineno)
      end

      def tag
        'apply'
      end

      private

      def decide_apply_end
        ->(token) { token.test('endapply') }
      end
    end
  end
end
