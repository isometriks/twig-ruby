# frozen_string_literal: true

require_relative 'support_defined_test'

module Twig
  module Node
    module Expression
      class Name < Expression::Base
        include Expression::SupportDefinedTest

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
            always_defined: false,
          }, lineno)
        end

        def compile(compiler)
          name = attributes[:name]

          compiler.add_debug_info(self)

          if attributes[:name][0] == '@'
            check = "context.call_context.instance_variable_defined?('#{name}')"
            get = "context.call_context.instance_variable_get('#{name}')"
          else
            check = "context.key?(:#{name})"
            get = "context[:#{name}]"
          end

          if define_test_enabled?
            if attributes[:always_defined] || SPECIAL_VARS.key?(name)
              compiler.repr(true)
            else
              compiler.raw(check)
            end
          # @todo always defined, special vars
          elsif attributes[:ignore_strict_check]
            compiler.
              raw('(context[').
              string(name).
              raw('] || nil)')
          else
            compiler.
              raw("(#{check}").
              raw(" ? #{get}").
              raw(' : raise(::Twig::Error::Runtime.new("Variable \"#{').
              string(name).
              raw('}\" does not exist.", ').
              repr(lineno).
              raw(', source_context)))')
          end
        end
      end
    end
  end
end
