module Twig
  module Node
    class ModuleNode < Node
      def initialize(body, source)
        super({ body: })

        self.source_context = source
      end

      def compile(compiler)
        class_begin = <<~CLASS
          class #{compiler.environment.template_class(source_context.name)} < ::Twig::Template
            def call(context)
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
