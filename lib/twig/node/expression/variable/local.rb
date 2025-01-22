# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Variable
        class Local < Expression::Base
          # @param [String|Integer|nil]
          def initialize(name, lineno)
            if %w[true false none null nil].include?(name.to_s.downcase)
              raise Error::Syntax.new("You cannot assign a value to #{name}", lineno)
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
