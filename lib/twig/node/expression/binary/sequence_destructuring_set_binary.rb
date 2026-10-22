# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class SequenceDestructuringSetBinary < Binary::Base
          def initialize(left, right, lineno)
            @variables = []

            left.each_value do |value|
              if value.is_a?(Expression::EmptySlot)
                @variables << nil
              elsif value.is_a?(Variable::Context)
                @variables << value.attributes[:name]
              else
                raise Error::Syntax.new(
                  "Cannot assign to \"#{value.class}\", only variables can be assigned in destructuring.",
                  lineno
                )
              end
            end

            super
          end

          def compile(compiler)
            compiler.
              add_debug_info(self).
              raw('::Twig::Runtime::Destructuring.sequence(context, [')

            @variables.each_with_index do |name, i|
              compiler.raw(', ') if i.positive?
              compiler.repr(name)
            end

            compiler.raw('], ').subcompile(nodes[:right]).raw(')')
          end

          def operator(compiler)
            compiler.raw('=')
          end
        end
      end
    end
  end
end
