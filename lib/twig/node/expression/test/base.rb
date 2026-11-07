# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        class Base < Call
          # @param [Node::Expression::Base] node
          # @param [TwigTest] test
          # @param [Node::Base] arguments
          # @param [Integer] lineno
          def initialize(node, test, arguments, lineno)
            super({
              node:,
              arguments: arguments || Node::Empty.new,
            }, {
              name: test.name,
              type: :test,
              twig_callable: test,
            }, lineno)
          end

          private

          # Twig compiles a test such as same as into a PHP operator, whose
          # operand can't be unpacked, so PHP fails to parse the template
          def reject_spread
            spread = nodes[:arguments].nodes.each_value.find { |node| node.is_a?(Unary::Spread) }
            return unless spread

            raise Error::Syntax.new('syntax error, unexpected token "..."', spread.lineno, source_context)
          end

          # @return [Boolean]
          def spread?
            nodes[:arguments].nodes.each_value.any?(Unary::Spread)
          end
        end
      end
    end
  end
end
