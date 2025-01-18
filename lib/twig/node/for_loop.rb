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

        # @todo if with loop
        compiler.
          write("context[:loop] = {\n").
          write("  index0: 0,\n").
          write("  index: 1,\n").
          write("  first: true,\n").
          write("}\n")

        if attributes.key?(:with_loop)
          compiler.
            write("context[:loop][:index0] += 1\n").
            write("context[:loop][:index] += 1\n").
            write("context[:loop][:first] = false\n").
            write("if context[:loop].key?(:revindex0) && context[:loop].key?(:revindex)\n").
            indent.
            write("context[:loop][:revindex0] -= 1\n").
            write("context[:loop][:revindex] -= 1\n").
            write("context[:loop][:last] = (context[:loop][:revindex0] == 0)\n").
            outdent.
            write("end\n")
        end
      end
    end
  end
end
