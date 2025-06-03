# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class ConditionalTernary < InfixExpressionParser
        def parse(parser, left, token)
          then_expr = parser.parse_expression(precedence)

          else_expr = if parser.stream.next_if(Token::PUNCTUATION_TYPE, ':')
                        # Ternary operator (expr ? expr2 : expr3)
                        parser.parse_expression(precedence)
                      else
                        # Ternary without else (expr ? expr2)
                        Node::Expression::Constant.new('', token.lineno)
                      end

          Node::Expression::Ternary.new(left, then_expr, else_expr, token.lineno)
        end

        def name
          '?'
        end

        def description
          'Conditional operator (a ? b : c)'
        end

        def precedence
          0
        end

        def associativity
          LEFT
        end
      end
    end
  end
end
