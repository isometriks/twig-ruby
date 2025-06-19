# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class Elvis < Binary::Base
          include OperatorEscape

          def initialize(left, right, lineno)
            super

            nodes[:test] = left.dup
            left.attributes[:always_defined] = true
          end

          def compile(compiler)
            compiler.
              raw('((').
              subcompile(nodes[:test]).
              raw(') ? (').
              subcompile(nodes[:left]).
              raw(') : (').
              subcompile(nodes[:right]).
              raw('))')
          end

          def operand_names_to_escape
            %i[left right]
          end
        end
      end
    end
  end
end
