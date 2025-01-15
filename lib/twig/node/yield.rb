# frozen_string_literal: true

module Twig
  module Node
    class Yield < Node::Base
      def initialize(expr, body, name = nil, lineno)
        super({ expr:, body: }, { name: }, lineno)
      end

      def compile(compiler)
        compiler.
          write('@output_buffer.append = (').
          subcompile(nodes[:expr]).
          raw(' do')

        if attributes[:name]
          compiler.
            raw(" |#{attributes[:name]}|")
        end

        compiler.
          raw("\n").
          indent

        if attributes[:name]
          compiler.
            write("preserved_scope = context.dup\n").
            write("context.merge!({#{attributes[:name]}:})\n")
        end

        compiler.
          write('').
          subcompile(nodes[:body]).
          raw("\n")

        if attributes[:name]
          compiler.
            write("context = preserved_scope\n")
        end

        compiler.
          outdent.
          write("end);\n")
      end
    end
  end
end
