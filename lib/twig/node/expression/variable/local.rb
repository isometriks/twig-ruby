# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Variable
        class Local < Expression::Base
          RESERVED_NAMES = %w[varargs context macros blocks self].freeze

          # @param [String|Integer|nil]
          def initialize(name, lineno)
            if %w[true false none null nil].include?(name.to_s.downcase)
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

          def compile(compiler)
            # @todo reserved vars
            attributes[:name] = compiler.var_name if attributes[:name].nil?

            compiler.raw(attributes[:name].to_s)
          end
        end
      end
    end
  end
end
