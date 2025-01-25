# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Hash < Array
        def compile(compiler)
          compiler.
            raw('{').
            indent

          first = true

          key_value_pairs.each do |key, value|
            unless first
              compiler.raw(', ')
            end

            first = false

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
