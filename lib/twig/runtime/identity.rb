# frozen_string_literal: true

module Twig
  module Runtime
    # The === and !== operators and the same as test, which compare values
    # the way PHP's === does instead of with Ruby's loose ==
    module Identity
      # Values are the same when they are eql?, so 1 and 1.0 are not but two
      # equal strings are, and an object is only the same as itself unless it
      # defines eql?. Arrays and hashes are the same when their elements are,
      # and hashes also need their keys in the same order, as PHP arrays do.
      #
      # @param [Object] left
      # @param [Object] right
      # @return [Boolean]
      def self.same?(left, right)
        case left
        when Hash
          right.is_a?(Hash) && left.size == right.size &&
            left.each_pair.zip(right.each_pair).all? do |(left_key, left_value), (right_key, right_value)|
              left_key.eql?(right_key) && same?(left_value, right_value)
            end
        when Array
          right.is_a?(Array) && left.size == right.size &&
            left.zip(right).all? { |left_value, right_value| same?(left_value, right_value) }
        else
          left.eql?(right)
        end
      end
    end
  end
end
