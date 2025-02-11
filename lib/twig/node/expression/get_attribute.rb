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
            write('::Twig::Extension::Core.get_attribute(').
            subcompile(nodes[:node]).
            raw(', ').
            subcompile(nodes[:attribute]).
            raw(', ').
            repr(attributes[:type])

          if nodes.key?(:arguments)
            compiler.
              raw(', arguments: ').
              subcompile(nodes[:arguments])
          end

          compiler.
            raw(')')
        end
      end
    end
  end
end
