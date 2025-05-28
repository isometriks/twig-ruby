# frozen_string_literal: true

module Twig
  module Node
    module Expression
      # Represents a parent node
      class Parent < Expression::Base
        # @param [String] name
        # @param [Integer] lineno
        def initialize(name, lineno)
          super({}, { output: false, name: }, lineno)
        end

        def compile(compiler)
          if attributes[:output]
            compiler.add_debug_info(self)
            raise NotImplementedError
          else
            compiler.
              raw('render_parent_block(').
              string(attributes[:name]).
              raw(', context, blocks)')
          end
        end
      end
    end
  end
end
