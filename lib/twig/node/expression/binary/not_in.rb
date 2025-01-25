# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class NotIn < Binary::Base
          def compile(compiler)
            compiler.
              raw('!::Twig::Extension::Core.in_filter(').
              subcompile(nodes[:left]).
              raw(', ').
              subcompile(nodes[:right]).
              raw(')')
          end
        end
      end
    end
  end
end
