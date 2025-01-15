module Twig
  module Node
    module Expression
      class Call < Expression::Base

        private

        # @param [Compiler] compiler
        def compile_callable(compiler)
          callable = attributes[:twig_callable].callable

          compiler.
            raw("env.extension(%q[#{callable[0].class.name}]).#{callable[1]}")

          compile_arguments(compiler)
        end

        def compile_arguments(compiler)
          compiler.
            raw('(').
            subcompile(nodes[:node]).
            raw(')')
        end
      end
    end
  end
end
