# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Variable
        class Template < Expression::Base
          RESERVED_NAMES = %w[varargs context macros blocks self].freeze

          # @param [String, Integer, nil] name
          # @param [Integer] lineno
          def initialize(name, lineno)
            if name && %w[true false none null nil].include?(name.to_s.downcase)
              raise Error::Syntax.new("You cannot assign a value to \"#{name}\"", lineno)
            end

            # Convert to integer if name is an integer or consists of digits only
            if !name.nil? && (name.is_a?(Integer) || name == name.to_i.to_s)
              name = name.to_i
            elsif RESERVED_NAMES.include?(name)
              name = "\u035C#{name}"
            end

            super({}, { name: }, lineno)
          end

          # @param [Compiler] compiler
          # @return [String]
          def name(compiler)
            if attributes[:name].nil?
              attributes[:name] = compiler.var_name
            end

            attributes[:name]
          end

          # @param [Compiler] compiler
          def compile(compiler)
            name_value = name(compiler)

            if name_value == '_self'
              compiler.raw('self')
            else
              compiler.
                raw('macros[').
                string(name_value).
                raw(']')
            end
          end
        end
      end
    end
  end
end
