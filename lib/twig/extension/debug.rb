# frozen_string_literal: true

module Twig
  module Extension
    class Debug < Extension::Base
      def functions
        [
          TwigFunction.new('dump', method(:dump), needs_environment: true, needs_context: true),
        ]
      end

      def dump(environment, context, *vars)
        return '' unless environment.debug?

        begin
          if vars.empty?
            context
          else
            vars.one? ? vars.first : vars
          end
        end.inspect
      end
    end
  end
end
