module Twig
  module Node
    module Expression
      class Constant < Expression
        def initialize(value, lineno)
          super({}, { value: }, lineno)
        end

        def compile(compiler)
          compiler.repr(attributes[:value])
        end
      end
    end
  end
end
