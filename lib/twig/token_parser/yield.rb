# frozen_string_literal: true

module Twig
  module TokenParser
    class Yield < TokenParser::Base
      def parse(token)
        stream = parser.stream
        lineno = token.lineno
        expr = parser.parse_expression
        arguments = []

        stream.expect(Token::NAME_TYPE, 'do')

        if stream.next_if(Token::OPERATOR_TYPE, '|')
          until stream.test(Token::OPERATOR_TYPE, '|')
            unless arguments.empty?
              stream.expect(Token::PUNCTUATION_TYPE, ',', 'Arguments must be separated by a comma')
            end

            arguments.push(stream.expect(Token::NAME_TYPE).value)
          end

          stream.expect(Token::OPERATOR_TYPE, '|')
        end

        stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(method(:decide_yield_end), drop_needle: true)
        stream.expect(Token::BLOCK_END_TYPE)

        # If it's a context variable, turn it into a helper method
        # ex: {% yield turbo_frame_tag do %}
        if expr.is_a?(Node::Expression::Variable::Context)
          expr = Node::Expression::HelperMethod.new(
            expr.attributes[:name],
            Node::Nodes.new({}),
            lineno
          )
        end

        Node::Yield.new(expr, body, arguments, lineno)
      end

      def tag
        'yield'
      end

      private

      def decide_yield_end(token)
        token.test('endyield')
      end
    end
  end
end
