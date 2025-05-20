# frozen_string_literal: true

module Twig
  module Extension
    class StringLoader < Extension::Base
      def functions
        [
          TwigFunction.new('template_from_string', static(:template_from_string), needs_environment: true),
        ]
      end

      # @param [Environment] environment
      # @param [String] string
      def self.template_from_string(environment, string, name = nil)
        environment.create_template(string, name)
      end
    end
  end
end
