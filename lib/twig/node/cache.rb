# frozen_string_literal: true

module Twig
  module Node
    class Cache < Node::Base
      def initialize(arguments, body, lineno)
        super({ arguments:, body: }, {}, lineno)
      end

      def compile(compiler)
        compiler.
          add_debug_info(self).
          # Cache method just writes strings onto the buffer, it doesn't return the fragment
          # so we can capture any output to the main buffer and output that instead
          write("context.output_buffer.safe_append = context.call_context.capture do\n").
          indent.
          write('context.call_context.cache(')

        first = true
        nodes[:arguments].nodes.each_value do |argument|
          compiler.raw(', ') unless first
          first = false

          compiler.subcompile(argument)
        end

        compiler.
          raw(") do\n").
          indent.
          # inside a capture block the original buffer is capturing so it's OK if we push strings there
          write("context.original_buffer.safe_append = context.buffer_and_return do\n").
          indent

        compiler.
          write("context.push_stack\n").
          subcompile(nodes[:body]).
          raw("\n").
          write("context.pop_stack\n")

        compiler.
          write("end.to_s\n").
          outdent.
          write("end\n").
          outdent.
          write("end\n").
          outdent
      end
    end
  end
end
