module Twig
  module Node
    module Expression
      class Ternary < Expression::Base
        def initialize(test, left, right, lineno)
          super({
            test:,
            left:,
            right:,
          }, {}, lineno)
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
      end
    end
  end
end
