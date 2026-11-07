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

        # Like a PHP closure, which gets a copy of the context, the function sees
        # the variables there were when it was made, and its arguments and any
        # assignments in it stay inside it: each call works on its own copy.
        def compile(compiler)
          compiler.
            add_debug_info(self).
            raw('->(context) { ->(')

          first = true
          nodes[:names].each_value do |name|
            compiler.raw(', ') unless first
            compiler.raw("__#{name.attributes[:name]}__")
            first = false
          end

          compiler.raw(') { ->(context) { ')

          nodes[:names].nodes.each_value do |name|
            compiler.
              raw("context[:#{name.attributes[:name]}] = ").
              raw("__#{name.attributes[:name]}__; ")
          end

          compiler.
            subcompile(nodes[:expr]).
            raw(' }.call(context.dup) } }.call(context.dup)')
        end
      end
    end
  end
end
