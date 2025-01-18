# frozen_string_literal: true

module Twig
  class AutoHash < Hash
    def add(*values)
      values.each do |value|
        self[length] = value
      end

      self
    end

    def <<(*values)
      add(*values)
    end
  end
end
