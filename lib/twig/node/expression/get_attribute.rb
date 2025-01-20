# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class GetAttribute < Expression::Base
        def initialize(node, attribute, arguments, type, lineno)
          nodes = { node:, attribute: }
          nodes[:arguments] = arguments if arguments

          super(nodes, { type: }, lineno)
        end

        def compile(compiler)
          var = compiler.var_name

          compiler.
            raw("(#{var} = ").
            subcompile(nodes[:node]).
            raw("\n").
            write("::Twig::Extension::Core.get_attribute(#{var}, ").
            subcompile(nodes[:attribute]).
            raw(', ').
            repr(attributes[:type]).
            raw('))')
        end
      end
    end
  end
end
