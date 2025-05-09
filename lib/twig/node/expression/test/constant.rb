# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        # Checks if a variable is the exact same value as a constant.
        #
        #    {% if post.status is constant('Post::PUBLISHED') %}
        #      the status attribute is exactly the same as Post::PUBLISHED
        #    {% endif %}
        #
        class Constant < Test::Base
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:node]).
              raw(' === ::Twig::Extension::Core.constant(')

            compiler.
              subcompile(nodes[:arguments].nodes[0])

            if nodes[:arguments].nodes.key?(1)
              compiler.
                raw(', ').
                subcompile(nodes[:arguments].nodes[1])
            end

            compiler.raw('))')
          end
        end
      end
    end
  end
end
