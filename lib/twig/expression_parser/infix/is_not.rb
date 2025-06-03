# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class IsNot < Is
        include ParsesArguments

        def parse(parser, left, token)
          Node::Expression::Unary::Not.new(super, token.lineno)
        end

        def name
          'is not'
        end
      end
    end
  end
end
