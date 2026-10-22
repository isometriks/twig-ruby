# frozen_string_literal: true

module Twig
  module Node
    # Represents a macro node.
    class Macro < Node::Base
      VARARGS_NAME = 'varargs'

      # @param [String] name
      # @param [Body] body
      # @param [Expression::Hash] arguments
      # @param [Integer] lineno
      def initialize(name, body, arguments, lineno)
        seen = {}
        arguments.key_value_pairs.each do |key, value|
          arg_name = key.attributes[:name]

          if "\u035C#{VARARGS_NAME}" == arg_name
            raise Error::Syntax.new(
              "The argument \"#{VARARGS_NAME}\" in macro \"#{name}\" cannot be defined because the variable " \
              "\"#{VARARGS_NAME}\" is reserved for arbitrary arguments.",
              value.lineno,
              value.source_context
            )
          end

          if seen.key?(arg_name)
            raise Error::Syntax.new(
              "Argument \"#{strip_reserved_prefix(arg_name)}\" is defined twice for macro \"#{name}\".",
              value.lineno,
              value.source_context
            )
          end

          seen[arg_name] = true
        end

        super({ body: body, arguments: arguments }, { name: name }, lineno)
      end

      # @param [Compiler] compiler
      def compile(compiler)
        compiler.
          add_debug_info(self).
          write("def macro_#{attributes[:name]}(call_context, ")

        arguments = nodes[:arguments]
        arguments.key_value_pairs.each do |key, value|
          compiler.
            subcompile(key).
            raw(': ').
            subcompile(value).
            raw(', ')
        end

        compiler.
          raw('**varargs').
          raw(")\n").
          write("  macros = @macros\n").
          write("  context = ::Twig::Runtime::Context.new({\n")

        arguments.key_value_pairs.each do |pair|
          key = pair[0]
          var = strip_reserved_prefix(key.attributes[:name])
          compiler.
            write('    ').
            string(var).
            raw(' => ').
            subcompile(key).
            raw(",\n")
        end

        capture_node = Node::Capture.new(nodes[:body], nodes[:body].lineno)

        compiler.
          write('    ').
          string(VARARGS_NAME).
          raw(' => ').
          raw("varargs,\n").
          write("  }, call_context:).merge!(env.globals, overwrite: false)\n\n").
          write("  blocks = {}\n\n").
          write('  ').
          subcompile(capture_node).
          raw("\n").
          write("end\n\n")
      end

      private

      # Reserved names (context, macros, ...) carry a prefix so they cannot clash
      # with the variables of the compiled method
      def strip_reserved_prefix(name)
        name.delete_prefix("\u035C")
      end
    end
  end
end
