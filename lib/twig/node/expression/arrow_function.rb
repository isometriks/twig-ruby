# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class ArrowFunction < Expression::Base
        # @param [Expression::Base] expr
        # @param [Node::Nodes] names
        # @param [Integer] lineno
        def initialize(expr, names, lineno)
          if !names.is_a?(Expression::Array) && !names.is_a?(Expression::Variable::Context)
            raise Error::Syntax.new(
              'The arrow function argument must be a list of variables or a single variable.',
              names.lineno,
              names.source_context
            )
          end

          if names.is_a?(Expression::Variable::Context)
            names = Expression::Array.new(AutoHash.new.add(
              Expression::Variable::AssignContext.new(names.attributes[:name], names.lineno)
            ), names.lineno)
          end

          super({ expr:, names: }, {}, lineno)
        end

        def compile(compiler)
          compiler.
            add_debug_info(self).
            raw('-> (')

          first = true
          nodes[:names].each_value do |name|
            compiler.raw(', ') unless first
            compiler.raw("__#{name.attributes[:name]}__")
            first = false
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
