module Twig
  module Node
    class Block < Node::Base
      def initialize(name, body, lineno)
        super({ body: }, { name: }, lineno)
      end

      def compile(compiler)
        compiler.
          write("def block_#{attributes[:name]}\n").
          indent.
          subcompile(nodes[:body]).
          outdent.
          write("end\n\n")
      end
    end
  end
end
