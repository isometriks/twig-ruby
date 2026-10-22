# frozen_string_literal: true

module Twig
  module Node
    # One name declared by the types tag
    class Type < Node::Base
      # @param [String] name
      # @param [String] type
      # @param [Boolean] optional
      # @param [Integer] lineno
      def initialize(name, type, optional, lineno)
        super({}, { name:, type:, optional: }, lineno)
      end
    end
  end
end
