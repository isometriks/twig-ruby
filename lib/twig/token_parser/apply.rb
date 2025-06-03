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
        filter = ref
        ep = parser.environment.expression_parsers.by_class(ExpressionParser::Infix::Filter.name)

        loop do
          filter = ep.parse(parser, filter, parser.current_token)

          unless parser.stream.test(Token::OPERATOR_TYPE, '|')
            break
          end

          parser.stream.next
        end

        parser.stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(method(:decide_apply_end), drop_needle: true)
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

      def decide_apply_end(token)
        token.test('endapply')
      end
    end
  end
end
