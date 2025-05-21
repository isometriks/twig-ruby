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
        arguments.key_value_pairs.each do |key, value|
          next unless "\u035C#{VARARGS_NAME}" == key.attributes[:name]

          raise Error::Syntax.new(
            "The argument \"#{VARARGS_NAME}\" in macro \"#{name}\" cannot be defined because the variable " \
            "\"#{VARARGS_NAME}\" is reserved for arbitrary arguments.",
            value.lineno,
            value.source_context
          )
        end

        super({ body: body, arguments: arguments }, { name: name }, lineno)
      end

      # @param [Compiler] compiler
      def compile(compiler)
        compiler.
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
          var = key.attributes[:name]
          if var.start_with?("\u035C")
            var = var[("\u035C".length)..]
          end
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
          write("  }.merge(env.globals), call_context:)\n\n").
          write("  blocks = {}\n\n").
          write('  ').
          subcompile(capture_node).
          raw("\n").
          write("end\n\n")
      end
    end
  end
end
