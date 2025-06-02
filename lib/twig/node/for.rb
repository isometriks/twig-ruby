# frozen_string_literal: true

module Twig
  module Node
    class For < Node::Base
      def initialize(key_target, value_target, seq, if_expr, body, else_expr, lineno)
        unless if_expr.nil?
          body = If.new(Nodes.new(AutoHash.new.add(if_expr, body)), nil, lineno)
        end

        loop = ForLoop.new(lineno)
        body = Nodes.new(AutoHash.new.add(body, loop))

        nodes = {
          key_target:,
          value_target:,
          seq:,
          body:,
        }

        unless else_expr.nil?
          nodes[:else_expr] = else_expr
        end

        super(nodes, { with_loop: true }, lineno)
      end

      def compile(compiler)
        compiler.
          add_debug_info(self).
          write("context.push_stack\n").
          write('context[:_seq] = ::Twig::Extension::Core.ensure_hash(').
          subcompile(nodes[:seq]).
          raw(")\n")

        # @todo Missing some more loops stuff here

        if nodes.key?(:else_expr)
          compiler.write("context[:_iterated] = false\n")
        end

        key_var = compiler.var_name
        value_var = compiler.var_name

        compiler.
          write("context[:_seq].each do |#{key_var}, #{value_var}|\n").
          indent.
          write('').
          subcompile(nodes[:key_target]).
          raw(" = #{key_var}\n").
          write('').
          subcompile(nodes[:value_target]).
          raw(" = #{value_var}\n\n").
          subcompile(nodes[:body]).
          outdent.
          write("end\n")

        if nodes.key?(:else_expr)
          compiler.
            write("unless context[:_iterated]\n").
            indent.
            subcompile(nodes[:else_expr]).
            outdent.
            write("end\n")
        end

        compiler.
          write("context.pop_stack\n")
      end
    end
  end
end
