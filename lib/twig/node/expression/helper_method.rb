# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class HelperMethod < Expression::Base
        def initialize(name, args, lineno)
          super({ args: }, { name: }, lineno)
        end

        def compile(compiler)
          compiler.
            raw("@call_context.#{attributes[:name]}(")

          nodes[:args].nodes.each do |key, value|
            unless key.is_a?(Integer)
              compiler.raw("#{key}: ")
            end

            compiler.
              subcompile(value).
              raw(',')
          end

          compiler.
            raw(')')
        end
      end
    end
  end
end
