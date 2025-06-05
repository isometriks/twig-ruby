# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class Or < Boolean
          def operator(compiler)
            compiler.raw('||')
          end
        end
      end
    end
  end
end
