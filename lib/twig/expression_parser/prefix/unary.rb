# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Prefix
      class Unary < PrefixExpressionParser
        attr_reader :aliases, :precedence, :name

        def initialize(node_class, name, precedence, description: nil, aliases: [])
          super()

          @node_class = node_class
          @name = name
          @precedence = precedence
          @description = description
          @aliases = aliases
        end

        def parse(parser, token)
          @node_class.new(parser.parse_expression(precedence), token.lineno)
        end

        def description
          @description || ''
        end
      end
    end
  end
end
