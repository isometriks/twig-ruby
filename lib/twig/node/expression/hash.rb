# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Hash < Array
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
              when Variable::Context
                key = Unary::StringCast.new(key, key.lineno)
              when Variable::Local
                key_value = key.attributes[:name]
                key = Constant.new(key_value, key.lineno)
              when Constant
                key.attributes[:value]
              end

              compiler.
                subcompile(key).
                raw(' => ')
            end

            compiler.
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
