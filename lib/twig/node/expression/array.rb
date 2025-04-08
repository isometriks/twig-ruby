# frozen_string_literal: true

require_relative 'support_defined_test'

module Twig
  module Node
    module Expression
      class Array < Expression::Base
        include Expression::SupportDefinedTest

        def initialize(elements, lineno)
          super(elements, {}, lineno)

          @index = -1
        end

        # @param [Expression::Base] value
        # @param [Expression::Base|nil] key
        def add_element(value, key = nil)
          if key.nil?
            @index += 1
            key = Constant.new(@index, value.lineno)
          end

          nodes.add(key, value)
        end

        def compile(compiler)
          if define_test_enabled?
            return compiler.repr(true)
          end

          compiler.
            raw('[').
            indent

          first = true

          key_value_pairs.each do |pair|
            unless first
              compiler.raw(', ')
            end

            first = false

            compiler.
              subcompile(pair[1])
          end

          compiler.
            outdent.
            raw(']')
        end

        def key_value_pairs
          nodes.each_value.each_slice(2)
        end
      end
    end
  end
end
