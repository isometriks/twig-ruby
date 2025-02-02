# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class ArrowFunction < Expression::Base
        # @param [Expression::Base] expr
        # @param [Node::Nodes] names
        # @param [Integer] lineno
        def initialize(expr, names, lineno)
          super({ expr:, names: }, {}, lineno)
        end

        def compile(compiler)
          compiler.
            raw('-> (')

          nodes[:names].nodes.each do |i, name|
            compiler.raw(', ') if i.positive?
            compiler.raw("__#{name.attributes[:name]}__")
          end

          compiler.raw(') { ')

          nodes[:names].nodes.each_value do |name|
            compiler.
              raw("context[:#{name.attributes[:name]}] = ").
              raw("__#{name.attributes[:name]}__; ")
          end

          compiler.
            subcompile(nodes[:expr]).
            raw('}')
        end
      end
    end
  end
end
