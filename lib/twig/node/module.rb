# frozen_string_literal: true

module Twig
  module Node
    class Module < Node::Base
      def initialize(body, parent, blocks, source)
        nodes = {
          body:,
          blocks:,
        }
        nodes[:parent] = parent if parent

        super(nodes)

        self.source_context = source
      end

      def compile(compiler)
        class_begin = <<~CLASS
          class Twig::#{compiler.environment.template_class(source_context.name)} < ::Twig::Template
        CLASS

        class_end = <<~CLASS
          end
        CLASS

        compiler.
          raw(class_begin).
          indent.
          write("def call(context = {}, blocks = {})\n").
          indent

        if nodes.key?(:parent)
          compiler.
            write('load_template(').
            subcompile(nodes[:parent]).
            raw(").render(context, block_list.merge(blocks));\n")
        else
          compiler.
            subcompile(nodes[:body])
        end

        compiler.
          write("@output_buffer\n").
          outdent.
          write("end\n\n").
          subcompile(nodes[:blocks]).
          outdent

        compiler.
          indent.
          write("def block_list\n").
          indent.
          write("{\n").
          indent

        nodes[:blocks].nodes.each_value do |block|
          compiler.
            write("#{block.attributes[:name]}: self,\n")
        end

        compiler.
          outdent.
          write("}\n").
          outdent.
          write("end\n").
          outdent

        compiler.
          raw(class_end)
      end
    end
  end
end
