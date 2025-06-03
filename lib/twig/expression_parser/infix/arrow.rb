# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class Arrow < InfixExpressionParser
        def parse(parser, left, token)
          # As the expression of the arrow function is independent from the current precedence,
          # we want a precedence of 0
          Node::Expression::ArrowFunction.new(parser.parse_expression, left, token.lineno)
        end

        def name
          '=>'
        end

        def description
          'Arrow function (x => expr)'
        end

        def precedence
          250
        end

        def associativity
          LEFT
        end
      end
    end
  end
end
