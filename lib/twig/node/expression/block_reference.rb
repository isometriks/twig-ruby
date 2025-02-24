# frozen_string_literal: true

module Twig
  module Node
    module Expression
      # Represents a block reference node
      class BlockReference < Expression::Base
        # @param [String] name
        # @param [String, nil] template
        # @param [Integer] lineno
        def initialize(name, template, lineno)
          nodes = { name: }
          nodes[:template] = template unless template.nil?

          super(nodes, { output: false }, lineno)
        end

        def compile(compiler)
          # @todo defined block test
          # @todo load block from specific template
          # @todo figure out this hack of returning empty string to the output buffer
          # if ($this->definedTest) {
          #   $this->compileTemplateCall($compiler, 'hasBlock');
          # } else {
          compiler.
            write('""; yield_block(').
            subcompile(nodes[:name]).
            raw(', context)')
        end
      end
    end
  end
end
