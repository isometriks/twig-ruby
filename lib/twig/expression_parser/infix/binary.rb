# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class Binary < InfixExpressionParser
        attr_reader :associativity, :precedence, :aliases, :name

        def initialize(node_class, name, precedence, associativity = LEFT, description: nil, aliases: [])
          super()

          @node_class = node_class
          @name = name
          @precedence = precedence
          @associativity = associativity
          @description = description
          @aliases = aliases
        end

        def parse(parser, left, token)
          right = parser.parse_expression(
            left? ? precedence + 1 : precedence
          )

          @node_class.new(left, right, token.lineno)
        end

        def description
          @description || ''
        end
      end
    end
  end
end
