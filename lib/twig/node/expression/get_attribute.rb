# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class GetAttribute < Expression::Base
        include SupportDefinedTest

        def initialize(node, attribute, arguments, type, lineno)
          nodes = { node:, attribute: }
          nodes[:arguments] = arguments if arguments

          super(nodes, { type:, ignore_strict_check: false }, lineno)
        end

        def enable_defined_test
          super
          change_ignore_strict_check(self)
        end

        def compile(compiler)
          compiler.
            raw('::Twig::Extension::Core.get_attribute(env, source_context, ')

          if attributes[:ignore_strict_check]
            nodes[:node].attributes[:ignore_strict_check] = true
          end

          compiler.
            subcompile(nodes[:node]).
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
