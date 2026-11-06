# frozen_string_literal: true

module Twig
  module Node
    class For < Node::Base
      def initialize(key_target, value_target, seq, if_expr, body, else_expr, lineno)
        @loop = ForLoop.new(lineno)
        @loop.attributes[:else_expr] = !else_expr.nil?
        body = Nodes.new(AutoHash.new.add(body, @loop))

        # Wrap the loop marker too, so the loop only counts as iterated when
        # the condition lets an item through and the else clause still renders
        unless if_expr.nil?
          body = If.new(Nodes.new(AutoHash.new.add(if_expr, body)), nil, lineno)
        end

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
        iteration_var = compiler.var_name
        function_var = compiler.var_name

        compiler.
          add_debug_info(self).
          write("#{iteration_var} = ::Twig::Runtime::LoopIterator.new(").
          subcompile(nodes[:seq]).
          raw(")\n").
          write("#{function_var} = lambda do |iterator, context, blocks, recurse, depth|\n").
          indent.
          write("parent = context.dup\n")

        if attributes[:with_loop]
          compiler.
            write('context[:loop] = ::Twig::Runtime::LoopContext.new(').
            raw("iterator, parent, blocks, recurse, depth)\n")
        end

        # Like PHP's $iterated, the else flag is a local of this loop's lambda
        # rather than a template variable; a fresh name keeps a nested loop's
        # lambda, which closes over this one, from sharing it
        if nodes.key?(:else_expr)
          iterated_var = compiler.var_name
          @loop.attributes[:iterated_var] = iterated_var
          compiler.write("#{iterated_var} = false\n")
        end

        key_var = compiler.var_name
        value_var = compiler.var_name

        compiler.
          write("iterator.each do |#{key_var}, #{value_var}|\n").
          indent.
          write('').
          subcompile(nodes[:key_target]).
          raw(" = #{key_var}\n").
          write('').
          subcompile(nodes[:value_target]).
          raw(" = #{value_var}\n").
          subcompile(nodes[:body]).
          outdent.
          write("end\n")

        if nodes.key?(:else_expr)
          compiler.
            write("unless #{iterated_var}\n").
            indent.
            subcompile(nodes[:else_expr]).
            outdent.
            write("end\n")
        end

        compiler.
          write("context.remove!(:#{nodes[:key_target].attributes[:name]}, ").
          raw(":#{nodes[:value_target].attributes[:name]}")

        if attributes[:with_loop]
          compiler.raw(', :loop')
        end

        compiler.
          raw(")\n").
          write("context.keep!(parent.keys)\n").
          write("context.merge!(parent, overwrite: false)\n").
          outdent.
          write("end\n").
          write("#{function_var}.call(#{iteration_var}, context, blocks, #{function_var}, 0)\n")
      end
    end
  end
end
