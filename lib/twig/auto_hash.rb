# frozen_string_literal: true

module Twig
  class AutoHash < Hash
    def add(*values)
      values.each do |value|
        self[next_key] = value
      end

      self
    end

    def <<(*values)
      add(*values)
    end

    private

    def next_key
      (keys.filter { |key| key.is_a?(Integer) }.max || -1) + 1
    end
  end
end
