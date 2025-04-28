# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Filter
        # Returns the value or the default value when it is undefined or empty.
        #
        # {{ var.foo|default('foo item on var is not defined') }}
        class Default < Expression::Filter
          # @param [Expression::Base] node
          # @param [TwigFilter] filter
          # @param [Node::Base] arguments
          # @param [Integer] lineno
          def initialize(node, filter, arguments, lineno)
            name = filter.name
            default = Expression::Filter.new(node, filter, arguments, node.lineno)

            if name == 'default' && (node.is_a?(Variable::Context) || node.is_a?(GetAttribute))
              test = Test::Defined.new(node.dup, TwigTest.new('defined'), Empty.new, node.lineno)
              false_case = arguments.empty? ? Expression::Constant.new('', node.lineno) : arguments.nodes[0]
              node = Ternary.new(test, default, false_case, node.lineno)
            else
              node = default
            end

            super
          end

          def compile(compiler)
            compiler.subcompile(nodes[:node])
          end
        end
      end
    end
  end
end
