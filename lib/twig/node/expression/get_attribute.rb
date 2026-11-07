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

          super(
            nodes,
            { type:, ignore_strict_check: false, null_safe:, is_short_circuited: false, var_name: nil },
            lineno
          )
        end

        def enable_defined_test
          super
          change_ignore_strict_check(self)
        end

        def compile(compiler)
          if attributes[:ignore_strict_check]
            nodes[:node].attributes[:ignore_strict_check] = true
          end

          # In foo?.bar.baz a nil foo short-circuits the whole chain, so the outermost access
          # tests the object of the nearest ?. and the accesses in between read it from there
          null_safe = attributes[:null_safe]
          null_safe_node = null_safe ? self : nearest_null_safe_node
          short_circuited = false

          if null_safe_node && !null_safe_node.attributes[:is_short_circuited]
            compiler.
              raw("((#{null_safe_node.var_name(compiler)} = ").
              subcompile(null_safe_node.nodes[:node]).
              raw(').nil? ? nil : ')

            null_safe_node.attributes[:is_short_circuited] = true
            short_circuited = true
          end

          compiler.raw('::Twig::Extension::Core.get_attribute(env, source_context, ')

          if null_safe
            compiler.raw(var_name(compiler))
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
            repr(nodes[:node].lineno).
            raw(')')

          return unless short_circuited

          compiler.raw(')')

          # The default filter and ?? compile the same node more than once (a dup shares its
          # attributes), so each compilation gets its own temporary and its own nil test
          null_safe_node.attributes[:is_short_circuited] = false
          null_safe_node.attributes[:var_name] = nil
        end

        # The temporary that holds the object of a null-safe access
        #
        # @param [Compiler] compiler
        # @return [String]
        def var_name(compiler)
          attributes[:var_name] ||= compiler.var_name
        end

        private

        # @return [GetAttribute, nil]
        def nearest_null_safe_node
          node = nodes[:node]

          while node.is_a?(GetAttribute)
            return node if node.attributes[:null_safe]

            node = node.nodes[:node]
          end

          nil
        end

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
