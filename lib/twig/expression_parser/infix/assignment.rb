# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class Assignment < InfixExpressionParser
        def parse(parser, left, token)
          # As in PHP, a target that is not a variable or a list is rejected
          # before the right side is parsed and an empty list only after it
          validate_target(parser, left, token)

          right = parser.parse_expression(precedence)

          validate_destructuring(parser, left, token)

          case left
          when Node::Expression::Array
            Node::Expression::Binary::SequenceDestructuringSetBinary.new(left, right, token.lineno)
          when Node::Expression::Hash
            Node::Expression::Binary::ObjectDestructuringSetBinary.new(left, right, token.lineno)
          else
            Node::Expression::Binary::SetBinary.new(left, right, token.lineno)
          end
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

        private

        def validate_target(parser, left, token)
          case left
          when Node::Expression::Array, Node::Expression::Hash, Node::Expression::Variable::Context
            nil
          else
            raise Error::Syntax.new(
              "Cannot assign to \"#{left.class}\", only variables can be assigned.",
              token.lineno,
              parser.stream.source
            )
          end
        end

        def validate_destructuring(parser, left, token)
          return unless left.is_a?(Node::Expression::Array) || left.is_a?(Node::Expression::Hash)
          return unless left.nodes.values.all? { |node| node.is_a?(Node::Expression::EmptySlot) }

          raise Error::Syntax.new(
            'Cannot destructure to an empty list of variables.',
            token.lineno,
            parser.stream.source
          )
        end
      end
    end
  end
end
