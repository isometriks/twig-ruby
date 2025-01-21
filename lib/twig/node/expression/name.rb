# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Name < Expression::Base
        SPECIAL_VARS = {
          '_self' => 'get_template_name',
          '_context' => 'context',
          '_charset' => 'env.charset',
        }.freeze

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

          if attributes[:name][0] == '@'
            check = "@call_context.instance_variable_defined?('#{name}')"
            get = "@call_context.instance_variable_get('#{name}')"
          else
            check = "context.key?(:#{name})"
            get = "context[:#{name}]"
          end

          compiler.
            raw("(#{check}").
            raw(" ? #{get}").
            raw(' : raise("#{').
            string(name).
            raw('} does not exist"))')
        end
      end
    end
  end
end
