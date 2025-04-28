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
          callable = attributes[:twig_callable].callable
          compiler.raw("(\n").
            indent.
            write('callable = ')

          case callable
          when ::Array
            extension, method = callable[0, 2]
            extension = extension.class.name if extension.is_a?(Extension::Base)

            compiler.
              raw("env.extension(%q[#{extension.delete_prefix('::')}]).method(:#{method})")
          when ::String
            class_name, method = callable.split('.', 2)

            compiler.
              raw("env.extension(%q[#{class_name.delete_prefix('::')}]).method(:#{method})")
          when ::Method
            # Instance method
            if callable.receiver.is_a?(Extension::Base)
              compiler.
                raw("env.extension(%q[#{callable.owner.name}]).method(:#{callable.name})")
            # Class method
            else
              compiler.
                raw("#{callable.receiver.name}.method(:#{callable.name})")
            end
          else
            raise "Callable not supported: #{callable.inspect}"
          end

          compiler.raw("\n")

          argument_nodes = [nodes.key?(:node) ? nodes[:node] : nil, *nodes[:arguments].nodes.values]
          has_spread = argument_nodes.any? { |node| node.is_a?(Unary::Spread) }

          if has_spread
            compiler.write('::Twig::ArgumentSpreader.new(callable).call')
          else
            compiler.write('callable.call')
          end

          compile_arguments(compiler)

          compiler.
            raw("\n").
            outdent.
            write(')')
        end

        def compile_arguments(compiler)
          first = true
          # @type [Twig::Callable] callable
          callable = attributes[:twig_callable]

          compiler.
            raw('(')

          if nodes.key?(:node)
            compiler.
              subcompile(nodes[:node])

            first = false
          end

          positional, kwargs = nodes[:arguments].nodes.partition do |key, node|
            key.is_a?(Integer) || node.is_a?(Unary::Spread)
          end.map(&:to_h)

          positional.each_value do |node|
            compiler.raw(', ') unless first
            compiler.subcompile(node)

            first = false
          end

          kwargs.each do |key, node|
            compiler.raw(', ') unless first
            compiler.
              raw("#{key}: ").
              subcompile(node)

            first = false
          end

          if callable.needs_charset?
            compiler.raw(', ') unless first
            compiler.raw('charset: env.charset')
            first = false
          end

          if callable.needs_environment?
            compiler.raw(', ') unless first
            compiler.raw('environment: env')
            first = false
          end

          if callable.needs_context?
            compiler.raw(', ') unless first
            compiler.raw('context:')
            first = false
          end

          compiler.
            raw(')')
        end
      end
    end
  end
end
