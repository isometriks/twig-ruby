# frozen_string_literal: true

module Twig
  module Node
    class Module < Node::Base
      # @param [Node::Body] body
      def initialize(body, parent, blocks, macros, traits, embedded_templates, source)
        nodes = {
          body:,
          blocks:,
          macros:,
          traits:,
        }
        nodes[:parent] = parent if parent

        super(
          nodes,
          {
            index: nil,
            embedded_templates:,
          },
          1
        )

        self.source_context = source
      end

      def index=(index)
        attributes[:index] = index
      end

      def compile(compiler)
        class_begin = <<~CLASS
          class Twig::#{compiler.environment.template_class(source_context.name, attributes[:index])} < ::Twig::Template
        CLASS

        class_end = <<~CLASS
          end
        CLASS

        compiler.
          raw(class_begin).
          indent

        compile_constructor(compiler)
        compile_get_parent(compiler)

        compiler.
          write("def call(context = {}, blocks = {})\n").
          indent.
          write("unless context.is_a?(::Twig::Runtime::Context)\n").
          indent.
          write("context = ::Twig::Runtime::Context.new(context)\n").
          outdent.
          write("end\n").
          write("macros = @macros.dup\n")

        if nodes.key?(:parent)
          compiler.
            write('@parent = load_template(').
            subcompile(nodes[:parent]).
            raw(', ').
            repr(nodes[:parent].lineno).
            raw(").call(context, self.blocks.merge(blocks));\n")
        else
          compiler.
            subcompile(nodes[:body])
        end

        compiler.
          write("context.output_buffer\n").
          outdent.
          write("end\n\n")

        # Blocks
        compiler.
          subcompile(nodes[:blocks])

        # Macros
        compiler.
          subcompile(nodes[:macros])

        compile_get_template_name(compiler)
        compile_traitable(compiler)
        compile_get_source_context(compiler)

        compiler.
          outdent.
          raw(class_end)

        attributes[:embedded_templates].nodes.each_value do |template|
          compiler.subcompile(template)
        end
      end

      private

      # @param [Compiler] compiler
      def compile_constructor(compiler)
        compiler.
          write("def initialize(*, **)\n").
          indent.
          write("super\n\n").
          write("@source = source_context\n")

        unless nodes.key?(:parent)
          compiler.write("@parent = false\n")
        end

        traits_count = nodes[:traits].length

        if traits_count.positive?
          nodes[:traits].nodes.each do |i, trait|
            node = trait.nodes[:template]

            compiler.
              write("_trait_#{i} = load_template(").
              subcompile(node).
              raw(', ').
              repr(node.lineno).
              raw(")\n").
              write("unless _trait_#{i}.traitable?\n").
              indent.
              write(%q[raise ::Twig::Error::Runtime.new('Template "' + ]).
              subcompile(node).
              raw(%q(+ '" cannot be used as a trait.', )).
              repr(node.lineno).
              raw(", @source)\n").
              outdent.
              write("end\n").
              write("_trait_#{i}_blocks = _trait_#{i}.blocks.dup\n\n")

            trait.nodes[:targets].nodes.each do |key, value|
              compiler.
                write("unless _trait_#{i}_blocks.key?(").
                string(key).
                raw(".to_sym)\n").
                indent.
                write('raise ::Twig::Error::Runtime.new("Block \"#{').
                string(key).
                raw('}\" is not defined in trait \"#{').
                subcompile(node).
                raw('}\"", ').
                repr(node.lineno).
                raw(", @source)\n").
                outdent.
                write("end\n\n").

                write("_trait_#{i}_blocks[").
                subcompile(value).
                raw(".to_sym] = _trait_#{i}_blocks[").
                symbol(key).
                raw("]\n").
                write("_trait_#{i}_blocks.delete(").
                symbol(key).
                raw(")\n").
                write('@trait_aliases[').
                subcompile(value).
                raw('.to_sym] = ').
                symbol(key).
                raw("\n\n")
            end
          end

          if traits_count > 1
            trait_names = (0...traits_count).map { |i| "_trait_#{i}_blocks" }

            compiler.
              write("@traits = {}.merge(#{trait_names.join(', ')})\n\n")
          else
            compiler.
              write("@traits = _trait_0_blocks\n\n")
          end

          compiler.
            write("@blocks = @traits.merge({\n")
        else
          compiler.
            write("@blocks = {\n")
        end

        compiler.indent

        nodes[:blocks].nodes.each_key do |name|
          compiler.
            write("#{name}: [self, 'block_#{name}'],\n")
        end

        compiler.outdent

        if traits_count.positive?
          compiler.
            write("})\n")
        else
          compiler.
            write("}\n")
        end

        compiler.
          outdent.
          write("end\n\n")
      end

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

      def compile_traitable(compiler)
        # A template can be used as a trait if:
        #   * it has no parent
        #   * it has no macros
        #   * it has no body
        #
        # Put another way, a template can be used as a trait if it
        # only contains blocks and use statements.
        traitable = !nodes.key?(:parent) && nodes[:macros].empty?

        if traitable
          body_node = nodes[:body].nodes[0]

          if body_node.empty?
            body_node = Node::Nodes.new({ 0 => body_node })
          end

          body_node.nodes.each_value do |node|
            if node.length.positive?
              traitable = false
              break
            end
          end
        end

        if traitable
          return
        end

        compiler.
          write("def traitable?\n").
          indent.
          write("false\n").
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
