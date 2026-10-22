# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class EmptySlot < Expression::Base
        def initialize(lineno)
          super({}, {}, lineno)
        end

        def compile(compiler)
          # Empty slot compiles to nothing
        end
      end
    end
  end
end
