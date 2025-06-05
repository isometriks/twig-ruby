# frozen_string_literal: true

require_relative 'boolean'

module Twig
  module Node
    module Expression
      module Binary
        class And < Boolean
          def operator(compiler)
            compiler.raw('&&')
          end
        end
      end
    end
  end
end
