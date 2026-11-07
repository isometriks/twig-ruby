# frozen_string_literal: true

module Twig
  module Node
    class If < Node::Base
      # @param [Boolean] plain_cast Cast the tests with PHP's plain (bool), as
      #   for ... if does, instead of Twig's TrueTest
      def initialize(tests, else_node, lineno, plain_cast: false)
        nodes = { tests: }
        nodes[:else] = else_node if else_node

        super(nodes, { plain_cast: }, lineno)
      end

      def compile(compiler)
        compiler.add_debug_info(self)
        cast = attributes[:plain_cast] ? 'cast?' : 'true?'

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
            raw("::Twig::Runtime::Truthiness.#{cast}(").
            subcompile(nodes[:tests].nodes[i]).
            raw("))\n").
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
