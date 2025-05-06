# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Filter
        class Raw < Expression::Filter
          # @param [Expression::Base] node
          # @param [TwigFilter|nil] filter
          # @param [Node::Base|nil] arguments
          # @param [Integer] lineno
          def initialize(node, filter, arguments, lineno)
            super(
              node,
              filter || TwigFilter.new('raw', nil, { is_safe: [:all] }),
              arguments || Node::Empty.new,
              lineno
            )
          end

          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:node]).
              raw(')')
          end
        end
      end
    end
  end
end
