# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class Concat < Binary::Base
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:left]).
              raw(').to_s + (').
              subcompile(nodes[:right]).
              raw(').to_s')
          end
        end
      end
    end
  end
end
