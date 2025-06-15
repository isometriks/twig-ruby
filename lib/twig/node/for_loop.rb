# frozen_string_literal: true

module Twig
  module Node
    class ForLoop < Node::Base
      def initialize(lineno)
        super({}, { with_loop: false, if_expr: false, else_expr: false }, lineno)
      end

      def compile(compiler)
        if attributes.key?(:else_expr)
          compiler.write("context[:_iterated] = true\n")
        end
      end
    end
  end
end
