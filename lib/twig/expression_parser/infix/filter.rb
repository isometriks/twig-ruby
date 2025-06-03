# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class Filter < InfixExpressionParser
        include ParsesArguments

        def parse(parser, left, _token)
          stream = parser.stream
          token = stream.expect(Token::NAME_TYPE)
          line = token.lineno

          arguments = if stream.test(Token::OPERATOR_TYPE, '(')
                        parse_named_arguments(parser)
                      else
                        Node::Empty.new
                      end

          filter = parser.filter(token.value, line)

          filter.node_class.new(left, filter, arguments, token.lineno)
        end

        def name
          '|'
        end

        def description
          'Twig filter call'
        end

        def precedence
          300
        end

        def associativity
          LEFT
        end
      end
    end
  end
end
