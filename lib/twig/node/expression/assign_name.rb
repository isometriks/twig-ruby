# frozen_string_literal: true

require_relative 'name'

module Twig
  module Node
    module Expression
      class AssignName < Expression::Name
        # @param [String] name
        # @param [Integer] lineno
        def initialize(name, lineno)
          if %w[true false none null nil].include?(name.downcase)
            raise Error::Syntax.new("You cannot assign a value to #{name}", lineno)
          end

          super
        end

        def compile(compiler)
          compiler.
            raw('context[').
            string(attributes[:name]).
            raw(']')
        end
      end
    end
  end
end
