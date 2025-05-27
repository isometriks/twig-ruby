# frozen_string_literal: true

require_relative 'support_defined_test'

module Twig
  module Node
    module Expression
      class Array < Expression::Base
        include Expression::SupportDefinedTest

        # @param [AutoHash] elements
        # @param [Integer] lineno
        def initialize(elements, lineno)
          super(elements, {}, lineno)
        end

        # @param [Expression::Base] value
        def add_element(value)
          nodes.add(value)
        end

        def compile(compiler)
          if define_test_enabled?
            return compiler.repr(true)
          end

          compiler.
            raw('[').
            indent

          first = true

          values.each do |value|
            unless first
              compiler.raw(', ')
            end

            first = false

            compiler.
              subcompile(value)
          end

          compiler.
            outdent.
            raw(']')
        end

        def values
          nodes.values
        end
      end
    end
  end
end
