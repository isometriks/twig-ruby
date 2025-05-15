# frozen_string_literal: true

module Twig
  module Node
    class Yield < Node::Base
      def initialize(expr, body, arguments, lineno)
        arguments = arguments.empty? ? {} : { arguments: }
        super({ expr:, body: }, arguments, lineno)
      end

      def compile(compiler)
        compiler.
          write('context.output_buffer.append = (').
          subcompile(nodes[:expr]).
          raw(' do')

        if attributes.key?(:arguments)
          compiler.
            raw(" |#{attributes[:arguments].join(', ')}|")
        end

        compiler.
          raw("\n").
          indent

        if attributes.key?(:arguments)
          compiler.
            write("context.push_stack\n").
            write('context.merge!({')

          attributes[:arguments].each do |argument|
            compiler.raw("#{argument}:,")
          end

          compiler.
            raw("})\n")
        end

        compiler.
          subcompile(nodes[:body]).
          raw("\n")

        if attributes.key?(:arguments)
          compiler.
            write("context.pop_stack\n")
        end

        compiler.
          outdent.
          write("end);\n")
      end
    end
  end
end
