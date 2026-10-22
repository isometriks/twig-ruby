# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class GetAttribute < Expression::Base
        include SupportDefinedTest

        # @param [Boolean] null_safe Whether the attribute is read with ?., which gives nil
        #   instead of reading it on nil
        def initialize(node, attribute, arguments, type, lineno, null_safe: false)
          nodes = { node:, attribute: }
          nodes[:arguments] = arguments if arguments

          super(nodes, { type:, ignore_strict_check: false, null_safe: }, lineno)
        end

        def enable_defined_test
          super
          change_ignore_strict_check(self)
        end

        def compile(compiler)
          if attributes[:ignore_strict_check]
            nodes[:node].attributes[:ignore_strict_check] = true
          end

          if (null_safe = attributes[:null_safe])
            var = compiler.var_name

            compiler.
              raw("((#{var} = ").
              subcompile(nodes[:node]).
              raw(').nil? ? nil : ')
          end

          compiler.raw('::Twig::Extension::Core.get_attribute(env, source_context, ')

          if null_safe
            compiler.raw(var)
          else
            compiler.subcompile(nodes[:node])
          end

          compiler.
            raw(', ').
            subcompile(nodes[:attribute]).
            raw(', ').
            repr(attributes[:type])

          if nodes.key?(:arguments)
            compiler.
              raw(', arguments: ').
              subcompile(nodes[:arguments])
          end

          if define_test_enabled?
            compiler.
              raw(', defined_test: true')
          end

          if attributes[:ignore_strict_check]
            compiler.
              raw(', ignore_strict_check: true')
          end

          compiler.
            raw(', lineno: ').
            repr(lineno).
            raw(')')

          compiler.raw(')') if null_safe
        end

        private

        # @param [GetAttribute] node]
        def change_ignore_strict_check(node)
          node.attributes[:optimizable] = false
          node.attributes[:ignore_strict_check] = true

          object_node = node.nodes[:node]

          if object_node.is_a?(GetAttribute)
            change_ignore_strict_check(object_node)
          end
        end
      end
    end
  end
end
