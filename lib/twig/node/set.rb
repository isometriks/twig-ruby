# frozen_string_literal: true

module Twig
  module Node
    class Set < Node::Base
      # @param [Boolean] capture
      # @param [Node::Base] names
      # @param [Node::Base] values
      # @param [Integer] lineno
      def initialize(capture, names, values, lineno)
        safe = false

        if capture
          # @todo Fill this out for capture node
        end

        super({ names:, values: }, { capture:, safe: }, lineno)
      end

      # @todo this doesn't work for multi targets
      def compile(compiler)
        if nodes[:names].length > 1
          compiler.write('')

          nodes[:names].nodes.each do |i, node|
            compiler.raw(', ') if i.positive?
            compiler.subcompile(node)
          end

          compiler.raw(' = ')

          nodes[:values].nodes.each do |i, node|
            compiler.raw(', ') if i.positive?
            compiler.subcompile(node)
          end

          compiler.raw("\n")
        else
          compiler.
            subcompile(nodes[:names], raw: false).
            raw(' = ').
            subcompile(nodes[:values]).
            raw("\n")
        end
      end
    end
  end
end
