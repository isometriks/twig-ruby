module Twig
  module Node
    module Expression
      module Binary
        class Concat < Binary::Base
          def operator(compiler)
            compiler.raw('+')
          end
        end
      end
    end
  end
end
