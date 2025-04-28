# frozen_string_literal: true

module Twig
  class Spread
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def array?
      value.is_a?(Array)
    end

    def hash?
      value.is_a?(Hash)
    end
  end
end
