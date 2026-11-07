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
              raw(' == ')

            if spread?
              # Unpacked at runtime, as PHP unpacks constant(...['X'])
              compiler.raw('::Twig::Runtime::ArgumentSpreader.new(::Twig::Extension::Core.method(:constant)).call(')
              nodes[:arguments].nodes.each_value.with_index do |node, index|
                compiler.raw(', ') unless index.zero?
                compiler.subcompile(node)
              end
            else
              compiler.raw('::Twig::Extension::Core.constant(')
              compiler.
                subcompile(nodes[:arguments].nodes[0])

              if nodes[:arguments].nodes.key?(1)
                compiler.
                  raw(', ').
                  subcompile(nodes[:arguments].nodes[1])
              end
            end

            compiler.raw('))')
          end
        end
      end
    end
  end
end
