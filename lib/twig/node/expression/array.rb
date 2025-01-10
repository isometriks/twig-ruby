module Twig
  module Node
    module Expression
      class Array < Expression::Base
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

          nodes[nodes.length] = key
          nodes[nodes.length] = value
        end

        def compile(compiler)
          compiler.
            write("{\n").
            indent

          key_value_pairs.each do |key, value|
            compiler.
              subcompile(key).
              raw(' => ').
              subcompile(value).
              raw(",\n")
          end

          compiler.
            outdent.
            write("}\n")
        end

        private

        def key_value_pairs
          nodes.each_value.each_cons(2)
        end
      end
    end
  end
end
