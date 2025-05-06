# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class Elvis < Binary::Base
          include OperatorEscape

          def operator(compiler)
            compiler.raw('||')
          end

          def operand_names_to_escape
            %i[left right]
          end
        end
      end
    end
  end
end
