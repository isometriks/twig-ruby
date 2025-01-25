# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class StartsWith < Binary::Base
          def compile(compiler)
            left = compiler.var_name
            right = compiler.var_name

            compiler.
              raw("(#{left} = ").
              subcompile(nodes[:left]).
              raw(').respond_to?(:start_with?) && ').
              raw("(#{right} = ").
              subcompile(nodes[:right]).
              raw(").respond_to?(:start_with?) && (#{left}.start_with?(#{right}))")
          end
        end
      end
    end
  end
end
