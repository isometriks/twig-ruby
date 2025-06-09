# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Ternary < Expression::Base
        include OperatorEscape

        def initialize(test, left, right, lineno)
          super({
            test:,
            left:,
            right:,
          }, {}, lineno)
        end

        def compile(compiler)
          compiler.
            raw('(::Twig::Extension::Core.bool(').
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
