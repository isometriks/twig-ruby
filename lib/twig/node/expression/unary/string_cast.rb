# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Unary
        class StringCast < Unary::Base
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:node]).
              raw('.to_s)')
          end
        end
      end
    end
  end
end
