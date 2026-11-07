# frozen_string_literal: true

module Twig
  module Node
    # Represents a tag that configures the template ("extends", "use", ...)
    # and that can only be used at the root of a template.
    class Config < Node::Base
      # @param [Integer] lineno
      def initialize(lineno)
        super({}, {}, lineno)
      end
    end
  end
end
