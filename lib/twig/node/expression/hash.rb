# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Hash < Expression::Base
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

          if key_value_pairs.any? { |_, value| value.is_a?(Unary::HashSpread) }
            compile_with_spreads(compiler)
          else
            compile_pairs(compiler, key_value_pairs)
          end
        end

        def key_value_pairs
          nodes.each_value.each_slice(2)
        end

        private

        # Spreads are merged at runtime, which renumbers their integer keys as
        # PHP does
        #
        # @param [Compiler] compiler
        def compile_with_spreads(compiler)
          compiler.raw('::Twig::Runtime::Spread.mapping(')

          key_value_pairs.
            slice_when { |a, b| a[1].is_a?(Unary::HashSpread) || b[1].is_a?(Unary::HashSpread) }.
            each_with_index do |pairs, index|
              compiler.raw(', ') if index.positive?

              if pairs[0][1].is_a?(Unary::HashSpread)
                compiler.
                  raw('::Twig::Runtime::Spread.new(').
                  subcompile(pairs[0][1].nodes[:node]).
                  raw(')')
              else
                compile_pairs(compiler, pairs)
              end
            end

          compiler.raw(')')
        end

        # @param [Compiler] compiler
        # @param [Enumerable] pairs
        def compile_pairs(compiler, pairs)
          compiler.
            raw('{').
            indent

          pairs.each_with_index do |(key, value), index|
            compiler.raw(', ') if index.positive?

            case key
            when Constant
              compiler.subcompile(key)
            when Variable::Local
              compiler.subcompile(Constant.new(key.attributes[:name], key.lineno))
            else
              # Any other key is computed at runtime
              compiler.
                raw('::Twig::Runtime::MappingKey.coerce(').
                subcompile(key).
                raw(')')
            end

            compiler.
              raw(' => ').
              subcompile(value)
          end

          compiler.
            outdent.
            raw('}')
        end
      end
    end
  end
end
