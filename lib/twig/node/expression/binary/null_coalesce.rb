# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class NullCoalesce < Binary::Base
          # @param [Compiler] compiler
          def compile(compiler)
            compiler.
              raw('((').
              subcompile(nodes[:left]).
              raw(' == nil) ? (').
              subcompile(nodes[:right]).
              raw(') : (').
              subcompile(nodes[:left]).
              raw('))')
          end
        end
      end
    end
  end
end
