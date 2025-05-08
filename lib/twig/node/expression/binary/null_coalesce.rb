# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class NullCoalesce < Binary::Base
          include OperatorEscape

          def initialize(left, right, lineno)
            super

            test = Test::Defined.new(left.dup, TwigTest.new('defined'), Node::Empty.new, left.lineno)

            unless left.is_a?(Expression::BlockReference)
              test = Binary::And.new(
                test,
                Unary::Not.new(
                  Test::Null.new(left, TwigTest.new('null'), Node::Empty.new, left.lineno),
                  left.lineno
                ),
                left.lineno
              )
            end

            left.attributes[:always_defined] = true
            nodes[:test] = test
          end

          # @param [Compiler] compiler
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
