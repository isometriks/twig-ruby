# frozen_string_literal: true

module Twig
  module Extension
    class StringLoader < Extension::Base
      def functions
        [
          TwigFunction.new('template_from_string', static(:template_from_string), needs_environment: true),
        ]
      end

      # @param [String] string
      # @param [Environment] environment
      def self.template_from_string(string, name = nil, environment:)
        environment.create_template(string, name)
      end
    end
  end
end
