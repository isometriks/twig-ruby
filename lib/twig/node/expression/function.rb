# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Function < Call
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

        def compile(compiler)
          if attributes[:name] == 'constant' && attributes[:is_defined_test]
            nodes[:arguments].nodes[:check_defined] = Expression::Constant.new(true, lineno)
          end

          super
        end
      end
    end
  end
end
