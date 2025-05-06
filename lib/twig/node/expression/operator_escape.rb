# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module OperatorEscape
        def operand_names_to_escape
          raise NotImplementedError
        end
      end
    end
  end
end
