# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class Concat < Binary::Base
          def compile(compiler)
            compiler.
              raw('(::Twig::Runtime::StringCast.cast(').
              subcompile(nodes[:left]).
              raw(') + ::Twig::Runtime::StringCast.cast(').
              subcompile(nodes[:right]).
              raw('))')
          end
        end
      end
    end
  end
end
