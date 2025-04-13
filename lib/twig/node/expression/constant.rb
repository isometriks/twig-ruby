# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Constant < Expression::Base
        include Expression::SupportDefinedTest

        def initialize(value, lineno)
          super({}, { value: }, lineno)
        end

        def compile(compiler)
          compiler.repr(define_test_enabled? || attributes[:value])
        end
      end
    end
  end
end
