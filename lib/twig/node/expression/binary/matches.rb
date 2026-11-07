# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class Matches < Binary::Base
          def initialize(left, right, lineno)
            # A constant pattern is checked when the template compiles, not each time it renders
            if right.is_a?(Constant)
              regexp = right.attributes[:value]

              begin
                Extension::Core.pcre_to_regexp(regexp)
              rescue RegexpError => e
                raise Error::Syntax.new(
                  "Regexp \"#{regexp}\" passed to \"matches\" is not valid: #{e.message}.",
                  lineno
                )
              end
            end

            super
          end

          def compile(compiler)
            compiler.
              raw('::Twig::Extension::Core.matches(').
              subcompile(nodes[:right]).
              raw(', ').
              subcompile(nodes[:left]).
              raw(')')
          end

          def operator(compiler)
            compiler.raw('')
          end
        end
      end
    end
  end
end
