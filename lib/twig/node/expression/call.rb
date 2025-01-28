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

          if callable.is_a?(::Array)
            compiler.
              raw("env.extension(%q[#{callable[0].class.name}]).#{callable[1]}")
          elsif callable.is_a?(::Method)
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

          compiler.
            raw(')')
        end
      end
    end
  end
end
