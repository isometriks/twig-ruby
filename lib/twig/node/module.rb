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
          indent

        compile_get_parent(compiler)

        compiler.
          write("def call(context = {}, blocks = {})\n").
          indent

        if nodes.key?(:parent)
          compiler.
            write('load_template(').
            subcompile(nodes[:parent]).
            raw(").call(context, block_list.merge(blocks));\n")
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
          raw("\n")

        compile_get_template_name(compiler)
        compile_get_source_context(compiler)

        compiler.
          outdent.
          raw(class_end)
      end

      private

      # @param [Compiler] compiler
      def compile_get_parent(compiler)
        unless nodes.key?(:parent)
          return
        end

        parent = nodes[:parent]

        compiler.
          write("private def do_get_parent(context)\n").
          indent.
          write('')

        if parent.is_a?(Node::Expression::Constant)
          compiler.subcompile(parent)
        else
          compiler.
            raw('load_template(').
            subcompile(parent).
            raw(', ').
            repr(source_context.name).
            raw(', ').
            repr(parent.lineno).
            raw(')')
        end

        compiler.
          raw("\n").
          outdent.
          write("end\n\n")
      end

      def compile_get_template_name(compiler)
        compiler.
          write("def template_name\n").
          indent.
          write('').
          repr(source_context.name).
          raw("\n").
          outdent.
          write("end\n\n")
      end

      def compile_get_source_context(compiler)
        compiler.
          write("def source_context\n").
          indent.
          write('::Twig::Source.new(').
          string(compiler.environment.debug? ? source_context.code : '').
          raw(', ').
          string(source_context.name).
          raw(', ').
          string(source_context.path).
          raw(")\n").
          outdent.
          write("end\n")
      end
    end
  end
end
