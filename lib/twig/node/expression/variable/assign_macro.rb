# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Variable
        class AssignMacro < Expression::Base
          # @param [Variable::Macro] var
          # @param [Boolean] global
          def initialize(var, global: true)
            super({ var: }, { global: }, var.lineno)
          end

          def compile(compiler)
            # @var [Macro] var
            var = nodes[:var]

            compiler.
              add_debug_info(self).
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
