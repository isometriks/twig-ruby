# frozen_string_literal: true

module Twig
  module TokenParser
    #  {% for user in users %}
    #    <li>{{ user.name }}</li>
    #  {% endfor %}
    class For < Base
      def parse(token)
        lineno = token.lineno
        stream = parser.stream

        targets = parse_assignment_expression
        stream.expect(Token::OPERATOR_TYPE, 'in')
        seq = parser.parse_expression

        if_expr = nil
        if stream.next_if(Token::NAME_TYPE, 'if')
          if_expr = parser.parse_expression
        end

        stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(method(:decide_for_fork))

        if stream.next.value == 'else'
          stream.expect(Token::BLOCK_END_TYPE)
          else_expr = parser.subparse(method(:decide_for_end), drop_needle: true)
        else
          else_expr = nil
        end

        stream.expect(Token::BLOCK_END_TYPE)

        if targets.nodes.length > 1
          key_target = targets.nodes[0]
          key_target = Node::Expression::Variable::AssignContext.new(
            key_target.attributes[:name],
            key_target.lineno
          )
          value_target = targets.nodes[1]
        else
          key_target = Node::Expression::Variable::AssignContext.new('_key', lineno)
          value_target = targets.nodes[0]
        end

        value_target = Node::Expression::Variable::AssignContext.new(
          value_target.attributes[:name],
          value_target.lineno
        )

        Node::For.new(key_target, value_target, seq, if_expr, body, else_expr, lineno)
      end

      def tag
        'for'
      end

      private

      def decide_for_fork(token)
        token.test(%w[else endfor])
      end

      def decide_for_end(token)
        token.test(%w[endfor])
      end
    end
  end
end
