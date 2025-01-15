# frozen_string_literal: true

module Twig
  module TokenParser
    # Marks a section of a template as being reusable.
    #
    #  {% if condition %}
    #    Something
    #  {% else %}
    #    Something else
    #  {% endif %}
    class If < Base
      def parse(token)
        lineno = token.lineno
        expr = parser.expression_parser.parse_expression
        stream = parser.stream
        stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(decide_if_fork)
        tests = [expr, body]
        else_node = nil

        if_ended = false
        until if_ended
          case stream.next.value
          when 'else'
            stream.expect(Token::BLOCK_END_TYPE)
            else_node = parser.subparse(decide_if_end)
          when 'elsif', 'elseif'
            expr = parser.expression_parser.parse_expression
            stream.expect(Token::BLOCK_END_TYPE)
            body = parser.subparse(decide_if_fork)
            tests.push(expr, body)
          when 'endif'
            if_ended = true
          else
            raise 'Unexpected end of template, expect else, elseif, or endif'
          end
        end

        stream.expect(Token::BLOCK_END_TYPE)

        tests_hash = tests.
          each_with_index.
          to_h { |t, i| [i, t] }

        Node::If.new(Node::Nodes.new(tests_hash), else_node, lineno)
      end

      def tag
        'if'
      end

      private

      def decide_if_end
        ->(token) { token.test(%w[endif]) }
      end

      def decide_if_fork
        ->(token) { token.test(%w[elseif elsif else endif]) }
      end
    end
  end
end
