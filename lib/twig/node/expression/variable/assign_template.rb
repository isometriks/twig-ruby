# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Variable
        class AssignTemplate < Expression::Base
          # @param [Variable::Template] var
          # @param [Boolean] global
          def initialize(var, global: true)
            super({ var: }, { global: }, var.lineno)
          end

          def compile(compiler)
            # @var [Template] var
            var = nodes[:var]

            compiler.
              write('macros[').
              string(var.name(compiler)).
              raw('] = ')

            if attributes[:global]
              compiler.
                raw('@macros[').
                string(var.name(compiler)).
                raw('] = ')
            end
          end
        end
      end
    end
  end
end
