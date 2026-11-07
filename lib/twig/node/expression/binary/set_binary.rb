# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class SetBinary < Binary::Base
          def initialize(left, right, lineno)
            name = left.attributes[:name]
            left = Variable::AssignContext.new(name, left.lineno)

            super
          end

          def operator(compiler)
            compiler.raw('=')
          end
        end
      end
    end
  end
end
