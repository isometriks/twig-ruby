# frozen_string_literal: true

module Twig
  module Node
    module Expression
      # Represents a block reference node
      class BlockReference < Expression::Base
        include SupportDefinedTest

        # @param [String] name
        # @param [String, nil] template
        # @param [Integer] lineno
        def initialize(name, template, lineno)
          nodes = { name: }
          nodes[:template] = template unless template.nil?

          super(nodes, { output: false }, lineno)
        end

        def compile(compiler)
          # @todo figure out this hack of returning empty string to the output buffer
          #   should we be using the attributes[:output]?
          if define_test_enabled?
            compile_template_call(compiler, 'block?')
          else
            compiler.
              write('""; ')

            compile_template_call(compiler, 'yield_block')
          end
        end

        private

        def compile_template_call(compiler, method)
          if nodes.key?(:template)
            compiler.
              write('load_template(').
              subcompile(nodes[:template]).
              raw(', ').
              repr(lineno).
              raw(')')
          else
            compiler.write('self')
          end

          compiler.raw(".#{method}")

          compile_block_arguments(compiler)
        end

        def compile_block_arguments(compiler)
          compiler.
            raw('(').
            subcompile(nodes[:name]).
            raw(', context')

          unless nodes.key?(:template)
            compiler.raw(', blocks')
          end

          compiler.raw(')')
        end
      end
    end
  end
end
