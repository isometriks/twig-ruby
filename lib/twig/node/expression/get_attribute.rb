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
          compiler.
            write('(temp = ').
            subcompile(nodes[:node]).
            raw("\n").
            write('temp.respond_to?(').
            subcompile(nodes[:attribute]).
            raw(') ? temp.public_send(').
            subcompile(nodes[:attribute]).
            raw(') : temp[').
            subcompile(nodes[:attribute]).
            raw("])\n\n")
        end
      end
    end
  end
end
