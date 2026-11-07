# frozen_string_literal: true

module Twig
  module Node
    class With < Node::Base
      # @param [Node::Base] body
      # @param [Node::Base|nil] variables
      # @param [Boolean] only
      # @param [Integer] lineno
      def initialize(body, variables, only, lineno)
        nodes = { body: }
        nodes[:variables] = variables unless variables.nil?

        super(nodes, { only: }, lineno)
      end

      def compile(compiler)
        compiler.
          add_debug_info(self).
          write("context.push_stack\n")

        if nodes.key?(:variables)
          var_name = compiler.var_name

          compiler.
            write("#{var_name} = ").
            subcompile(nodes[:variables]).
            write("\n").
            write("unless #{var_name}.is_a?(::Hash) || #{var_name}.is_a?(::Enumerable)\n").
            indent.
            write("raise ::Twig::Error::Runtime.new('Variables passed to the \"with\" tag must be a mapping.',").
            repr(nodes[:variables].lineno).
            raw(", source_context)\n").
            outdent.
            write("end\n").
            # Like PHP's toArray: a sequence gets integer keys and an
            # enumerable yielding pairs gives its keys and values
            write("#{var_name} = ::Twig::Runtime::EnumerableHash.from(#{var_name}).to_h ").
            raw("unless #{var_name}.is_a?(::Hash)\n")

          # The variables are evaluated before only clears the context, so
          # they can still read it
          compiler.write("context.clear\n") if attributes[:only]

          compiler.
            write("context.merge!(env.globals, overwrite: false)\n").
            write("context.merge!(#{var_name})\n")
        end

        compiler.
          subcompile(nodes[:body]).
          write("context.pop_stack\n")
      end
    end
  end
end
