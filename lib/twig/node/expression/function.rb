# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Function < Call
        include SupportDefinedTest

        # @param [TwigFunction] function
        # @param [Node::Base] arguments
        # @param [Integer] lineno
        def initialize(function, arguments, lineno)
          super({ arguments: }, {
            name: function.name,
            type: :function,
            twig_callable: function,
            is_defined_test: false,
          }, lineno)
        end

        def enable_defined_test
          if attributes[:name] == 'constant'
            super
          end
        end

        def compile(compiler)
          if attributes[:name] == 'constant' && define_test_enabled?
            nodes[:arguments].nodes[:defined_test] = Expression::Constant.new(true, lineno)
          end

          super
        end
      end
    end
  end
end
