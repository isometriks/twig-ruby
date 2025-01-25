# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class FloorDiv < Binary::Base
          def compile(compiler)
            compiler.raw('(')
            super
            compiler.raw(').floor.to_i')
          end

          def operator(compiler)
            compiler.raw('/')
          end
        end
      end
    end
  end
end
