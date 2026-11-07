# frozen_string_literal: true

module Twig
  module Runtime
    # The === and !== operators and the same as test, which compare values
    # the way PHP's === does instead of with Ruby's loose ==
    module Identity
      # Values are the same when they are eql?, so 1 and 1.0 are not but two
      # equal strings are, and an object is only the same as itself unless it
      # defines eql?. Sequences and mappings are both PHP arrays, which are
      # the same when they have the same keys in the same order, holding the
      # same values, so [1, 2] is the same as {0: 1, 1: 2}. A key is read as
      # PHP stores it, so :a and "a" are one key, and so are "1" and 1.
      #
      # @param [Object] left
      # @param [Object] right
      # @return [Boolean]
      def self.same?(left, right)
        return left.eql?(right) unless array?(left) && array?(right)

        left.size == right.size &&
          pairs(left).zip(pairs(right)).all? do |(left_key, left_value), (right_key, right_value)|
            key(left_key).eql?(key(right_key)) && same?(left_value, right_value)
          end
      end

      def self.array?(value)
        value.is_a?(Array) || value.is_a?(Hash)
      end

      def self.pairs(value)
        value.is_a?(Hash) ? value.each_pair : value.each_with_index.map { |item, index| [index, item] }
      end

      def self.key(key)
        if MappingKey.integer?(key)
          key.to_i
        else
          key.is_a?(Symbol) ? key.to_s : key
        end
      end

      private_class_method :array?, :pairs, :key
    end
  end
end
