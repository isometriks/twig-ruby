# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Call < Expression::Base
        def compile(compiler)
          compile_callable(compiler)
        end

        private

        # @param [Compiler] compiler
        def compile_callable(compiler)
          argument_nodes = [nodes.key?(:node) ? nodes[:node] : nil, *nodes[:arguments].nodes.values]
          has_spread = argument_nodes.any? { |node| node.is_a?(Unary::Spread) }

          if has_spread
            compiler.
              raw('::Twig::Runtime::ArgumentSpreader.new(').
              raw(callable_method).
              raw(').call')
          else
            compiler.
              raw(callable_method).
              raw('.call')
          end

          compiler.
            raw("(\n").
            indent.
            write('')

          compile_arguments(compiler)

          compiler.
            raw("\n").
            outdent.
            write(')')
        end

        # @return [String]
        def callable_method
          # @type [Twig::Callable] callable
          twig_callable = attributes[:twig_callable]
          callable = twig_callable.callable

          case callable
          when ::Array
            if callable[0] == :runtime
              _, klass, method = callable

              "env.runtime(%q[#{klass}]).method(:#{method})"
            else
              extension, method = callable[0, 2]
              extension = extension.class.name if extension.is_a?(Extension::Base)

              "env.extension(%q[#{extension.delete_prefix('::')}]).method(:#{method})"
            end
          when ::String
            class_name, method = callable.split('.', 2)

            "env.extension(%q[#{class_name.delete_prefix('::')}]).method(:#{method})"
          when ::Method
            # Instance method
            if callable.receiver.is_a?(Extension::Base)
              "env.extension(%q[#{callable.owner.name}]).method(:#{callable.name})"
              # Class method
            else
              "#{callable.receiver.name}.method(:#{callable.name})"
            end
          when ::Proc
            "env.#{attributes[:type]}(%q[#{twig_callable.dynamic_name}]).callable"
          else
            raise "Callable not supported: #{callable.inspect}"
          end
        end

        def compile_arguments(compiler)
          first = true
          # @type [Twig::Callable] callable
          callable = attributes.fetch(:twig_callable, nil)

          callable&.arguments&.each do |argument|
            compiler.raw(', ') unless first

            compiler.string(argument)

            first = false
          end

          if nodes.key?(:node)
            compiler.raw(', ') unless first

            compiler.
              subcompile(nodes[:node])

            first = false
          end

          if callable&.needs_charset?
            compiler.raw(', ') unless first
            compiler.raw('env.charset')
            first = false
          end

          if callable&.needs_environment?
            compiler.raw(', ') unless first
            compiler.raw('env')
            first = false
          end

          if callable&.needs_context?
            compiler.raw(', ') unless first
            compiler.raw('context')
            first = false
          end

          # Only callables that come through without are helper methods, which still
          # can't be determined at compile time for Rails
          if callable
            positional, kwargs = Util::CallableArgumentsExtractor.
              new(self, callable, compiler.environment).
              extract_arguments(nodes[:arguments])
          else
            positional, kwargs = nodes[:arguments].nodes.partition do |key, node|
              key.is_a?(Integer) || node.is_a?(Unary::Spread)
            end.map(&:to_h)

            positional = positional.values
          end

          positional.each do |node|
            compiler.raw(', ') unless first
            compiler.subcompile(node)

            first = false
          end

          kwargs.each do |key, node|
            compiler.raw(', ') unless first
            compiler.
              raw("'#{key}': ").
              subcompile(node)

            first = false
          end
        end
      end
    end
  end
end
