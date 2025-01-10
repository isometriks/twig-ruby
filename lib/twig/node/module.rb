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
          #{compiler.environment.template_class(source_context.name)} = Class.new(::Twig::Template) do
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
            write('yield env.load_template(').
            string(nodes[:parent].attributes[:value]).
            raw(").render(context, block_list.merge(blocks))\n")
        else
          compiler.
            subcompile(nodes[:body])
        end

        compiler.
          outdent.
          write("end\n\n").
          subcompile(nodes[:blocks]).
          raw("\n\n").
          outdent

        compiler.
          write("def block_list\n").
          indent.
          write("{\n").
          indent

        nodes[:blocks].nodes.values.each do |block|
          compiler.
            write("#{block.attributes[:name]}: self,\n")
        end

        compiler.
          outdent.
          write("}\n").
          outdent.
          write("end\n\n")

        compiler.
          raw(class_end)
      end
    end
  end
end
