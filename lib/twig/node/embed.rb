# frozen_string_literal: true

require_relative 'include'

module Twig
  module Node
    class Embed < Include
      # we don't inject the module to avoid node visitors to traverse it twice (as it will
      # be already visited in the main module)
      def initialize(name, index, variables, only, ignore_missing, lineno)
        super(
          Expression::Constant.new('not_used', lineno),
          variables,
          only,
          ignore_missing,
          lineno
        )

        attributes[:name] = name
        attributes[:index] = index
      end

      private

      def add_get_template(compiler, template = '')
        compiler.
          raw('load(').
          string(attributes[:name]).
          raw(', ').
          repr(lineno).
          raw(', ').
          string(attributes[:index]).
          raw(')')

        if attributes[:ignore_missing]
          compiler.
            raw("\n").
            write("#{template}.get_parent(context)\n")
        end
      end
    end
  end
end
