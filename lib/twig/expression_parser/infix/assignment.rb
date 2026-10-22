# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class Assignment < InfixExpressionParser
        def parse(parser, left, token)
          right = parser.parse_expression(precedence)

          case left
          when Node::Expression::Array
            return Node::Expression::Binary::SequenceDestructuringSetBinary.new(left, right, token.lineno)
          when Node::Expression::Hash
            return Node::Expression::Binary::ObjectDestructuringSetBinary.new(left, right, token.lineno)
          when Node::Expression::Variable::Context
            return Node::Expression::Binary::SetBinary.new(left, right, token.lineno)
          end

          raise Error::Syntax.new(
            "Cannot assign to \"#{left.class}\", only variables can be assigned.",
            token.lineno,
            parser.stream.source
          )
        end

        def name
          '='
        end

        def description
          'Assignment operator'
        end

        def precedence
          0
        end

        def associativity
          RIGHT
        end

        def aliases
          []
        end
      end
    end
  end
end
