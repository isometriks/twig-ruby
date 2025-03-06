# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        # Checks if an expression is defined
        #
        #  {{ var is defined }}
        class Defined < Test::Base
          # @param [Node::Expression::Base] node
          # @param [TwigTest] name
          # @param [Node::Base] arguments
          # @param [Integer] lineno
          def initialize(node, name, arguments, lineno)
            unless node.is_a?(SupportDefinedTest)
              raise Error::Syntax.new('The "defined" test only works with simple variables', lineno)
            end

            node.enable_defined_test

            super
          end

          def compile(compiler)
            compiler.
              subcompile(nodes[:node])
          end
        end
      end
    end
  end
end
