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

          case callable
          when ::Array
            extension, method = callable[0, 2]
            extension = extension.class.name if extension.is_a?(Extension::Base)

            compiler.
              raw("env.extension(%q[#{extension.delete_prefix('::')}]).#{method}")
          when ::String
            class_name, method = callable.split('.', 1)

            compiler.
              raw("env.extension(%q[#{class_name.delete_prefix('::')}]).#{method}")
          when ::Method
            # Instance method
            if callable.receiver.is_a?(Extension::Base)
              compiler.
                raw("env.extension(%q[#{callable.owner.name}]).#{callable.name}")
            # Class method
            else
              compiler.
                raw("#{callable.receiver.name}.#{callable.name}")
            end
          else
            raise "Callable not supported: #{callable.inspect}"
          end

          compile_arguments(compiler)
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

          nodes[:arguments].nodes.each_value do |node|
            compiler.raw(', ') unless first
            compiler.subcompile(node)

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
