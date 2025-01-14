module Twig
  module Node
    class If < Node::Base
      def initialize(tests, else_node, lineno)
        nodes = { tests: }
        nodes[:else] = else_node if else_node

        super(nodes, {}, lineno)
      end

      def compile(compiler)
        (0...nodes[:tests].nodes.length).step(2).each do |i|
          if i.zero?
            compiler.
              raw("\n").
              write('if (')
          else
            compiler.
              outdent.
              write('elsif (')
          end

          compiler.
            subcompile(nodes[:tests].nodes[i]).
            raw(")\n").
            indent

          if nodes[:tests].nodes.key?(i + 1)
            compiler.
              subcompile(nodes[:tests].nodes[i + 1])
          end
        end

        if nodes.key?(:else)
          compiler.
            outdent.
            write("else\n").
            indent.
            subcompile(nodes[:else])
        end

        compiler.
          outdent.
          write("end\n\n")
      end
    end
  end
end
