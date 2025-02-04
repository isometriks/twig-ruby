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
        end
      end
    end
  end
end
