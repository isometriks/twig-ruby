# frozen_string_literal: true

module Twig
  module Node
    class Import < Node::Base
      # @param [Expression::Base] expr
      # @param [Expression::Base, Expression::Variable::AssignTemplate] var
      # @param [Integer] lineno
      def initialize(expr, var, lineno)
        super({ expr:, var: }, {}, lineno)
      end

      # @param [Compiler] compiler
      def compile(compiler)
        compiler.subcompile(nodes[:var])

        if nodes[:expr].is_a?(Expression::Variable::Context) && nodes[:expr].attributes[:name] == '_self'
          compiler.raw('self')
        else
          compiler.
            raw('load_template(').
            subcompile(nodes[:expr]).
            raw(', ').
            repr(lineno).
            raw(')')
        end

        compiler.raw("\n")
      end
    end
  end
end
