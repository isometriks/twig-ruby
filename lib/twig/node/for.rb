# frozen_string_literal: true

module Twig
  module Node
    class For < Node::Base
      def initialize(key_target, value_target, seq, if_expr, body, else_expr, lineno)
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
          write("context.push_stack\n").
          write('context[:_seq] = ::Twig::Extension::Core.ensure_hash(').
          subcompile(nodes[:seq]).
          raw(")\n")

        if nodes.key?(:else_expr)
          compiler.write("context[:_iterated] = false\n")
        end

        compiler.
          write("context[:_seq].each do |k, v|\n").
          indent.
          write('').
          subcompile(nodes[:key_target]).
          raw(" = k\n").
          write('').
          subcompile(nodes[:value_target]).
          raw(" = v\n\n").
          subcompile(nodes[:body]).
          outdent.
          write("end\n").
          write("context.pop_stack\n")
      end
    end
  end
end
