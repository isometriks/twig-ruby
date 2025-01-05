module Twig
  module Node
    class ModuleNode < Node
      def initialize(body)
        super({ body: })
      end

      def compile(compiler)
        class_begin = <<~CLASS
          class Whatever < ::Twig::Template
            def call
        CLASS

        class_end = <<~CLASS
            end
          end
        CLASS

        compiler.
          raw(class_begin).
          indent(2).
          subcompile(node(:body)).
          outdent(2).
          raw(class_end)
      end
    end
  end
end
