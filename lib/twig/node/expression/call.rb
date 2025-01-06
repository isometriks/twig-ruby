module Twig
  module Node
    module Expression
      class Call < Expression

        private

        # @param [Compiler] compiler
        def compile_callable(compiler)
          compiler.
            raw("env.filter('#{attributes[:name]}').callable")

          compile_arguments(compiler)
        end

        def compile_arguments(compiler)
          compiler.
            raw(".call(").
            subcompile(node(:node)).
            raw(")")
        end
      end
    end
  end
end
