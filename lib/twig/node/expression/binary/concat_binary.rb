module Twig
  module Node
    module Expression
      module Binary
        class ConcatBinary < Binary
          def operator(compiler)
            compiler.raw('+')
          end
        end
      end
    end
  end
end
