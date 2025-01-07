module Twig
  module Node
    module Expression
      class Array < Expression::Base
        def initialize(elements, lineno)
          super(elements, {}, lineno)
        end

        def compile(compiler)
          compiler.raw('# Would be an array here')
        end
      end
    end
  end
end
