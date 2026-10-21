# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class Arrow < InfixExpressionParser
        def parse(parser, left, token)
          arguments = left.is_a?(Node::Expression::Array) ? left.nodes.values : [left]
          arguments.each do |argument|
            name = argument.attributes.key?(:name) && argument.attributes[:name]
            next unless name.is_a?(String) && name.end_with?('?')

            raise Error::Syntax.new(
              "An arrow function argument cannot end with \"?\" (\"#{name}\").",
              token.lineno,
              parser.stream.source
            )
          end

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
