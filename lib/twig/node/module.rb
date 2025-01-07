module Twig
  module Node
    class Module < Node::Base
      def initialize(body, blocks, source)
        super({
          body:,
          blocks:,
        })

        self.source_context = source
      end

      def compile(compiler)
        class_begin = <<~CLASS
          class #{compiler.environment.template_class(source_context.name)} < ::Twig::Template
        CLASS

        class_end = <<~CLASS
          end
        CLASS

        compiler.
          raw(class_begin).
          indent.
          write("def call(context)\n").
          indent.
          subcompile(nodes[:body]).
          outdent.
          write("end\n\n").
          subcompile(nodes[:blocks]).
          raw("\n").
          outdent.
          raw(class_end)
      end
    end
  end
end
