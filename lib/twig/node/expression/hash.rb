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

          compiler.
            raw('{').
            indent

          first = true

          key_value_pairs.each do |key, value|
            unless first
              compiler.raw(', ')
            end

            first = false

            unless value.is_a?(Expression::Unary::HashSpread)
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

              compiler.raw(' => ')
            end

            compiler.
              subcompile(value)
          end

          compiler.
            outdent.
            raw('}')
        end

        def key_value_pairs
          nodes.each_value.each_slice(2)
        end
      end
    end
  end
end
