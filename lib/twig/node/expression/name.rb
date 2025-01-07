module Twig
  module Node
    module Expression
      class Name < Expression::Base
        SPECIAL_VARS = {
          '_self' => 'get_template_name',
          '_context' => 'context',
          '_charset' => 'env.charset',
        }

        # @param [String] name
        # @param [Integer] lineno
        def initialize(name, lineno)
          super({}, {
            name:,
            is_defined_test: false,
            ignore_strict_check: false,
            alwways_defined: false,
          }, lineno)
        end

        def compile(compiler)
          name = attributes[:name]

          compiler.
            raw("(context.key?(:#{name})").
            raw(" ? context[:#{name}]").
            raw(' : raise("#{').
            string(name).
            raw('} does not exist"))')
        end
      end
    end
  end
end
