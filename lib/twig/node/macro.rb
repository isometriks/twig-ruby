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

      # Compiles to a Runtime::Macro. The body binds the arguments by name from the Hash the
      # macro hands it, so no Ruby parameter or local is ever named after a Twig argument.
      #
      # @param [Compiler] compiler
      def compile(compiler)
        arguments = nodes[:arguments]

        compiler.
          raw('::Twig::Runtime::Macro.new(').
          string(attributes[:name]).
          raw(", ->(call_context, args) {\n").
          indent.
          add_debug_info(self).
          write("macros = @macros.dup\n").
          write("context = ::Twig::Runtime::Context.new({\n").
          indent

        arguments.key_value_pairs.each do |key, value|
          var = strip_reserved_prefix(key.attributes[:name])
          compiler.
            write('').
            string(var).
            raw(' => args.fetch(').
            string(var).
            raw(') { ').
            subcompile(value).
            raw(" },\n")
        end

        capture_node = Node::Capture.new(nodes[:body], nodes[:body].lineno)

        compiler.
          write('').
          string(VARARGS_NAME).
          raw(' => args[').
          string(VARARGS_NAME).
          raw("],\n").
          outdent.
          write("}, call_context:).merge!(env.globals, overwrite: false)\n\n").
          write("blocks = {}\n\n").
          write('').
          subcompile(capture_node).
          raw("\n").
          outdent.
          write('}, {')

        signature.each_with_index do |(name, has_default), index|
          compiler.
            raw(index.zero? ? ' ' : ', ').
            string(name).
            raw(' => ').
            repr(has_default)
        end

        compiler.raw(signature.empty? ? '}, nil)' : ' }, nil)')
      end

      private

      # The declared argument names mapped to whether they have an explicit default value
      #
      # @return [Hash{String => Boolean}]
      def signature
        nodes[:arguments].key_value_pairs.to_h do |key, value|
          [strip_reserved_prefix(key.attributes[:name]), !value.attributes.fetch(:is_implicit, false)]
        end
      end

      # Reserved names (context, macros, ...) carry a prefix so they cannot clash
      # with the variables of the compiled method
      def strip_reserved_prefix(name)
        name.delete_prefix("\u035C")
      end
    end
  end
end
