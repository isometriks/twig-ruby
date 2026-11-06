# frozen_string_literal: true

module Twig
  module Runtime
    class Spread
      attr_reader :value

      # Builds a sequence literal with spreads, as PHP builds an array: a
      # spread's integer keys are renumbered after the items so far and its
      # string keys are kept, so [0, ...[1, 2]] is [0, 1, 2] and
      # [...{a: 1}, 2] is {a: 1, 0: 2}. The result is a sequence unless a
      # spread adds a string key, which makes it a mapping, as in PHP.
      #
      # @param [Array<Object, Spread>] items the literal's items, with each
      #   spread as a Spread between them
      # @return [Array, Hash]
      def self.sequence(*items)
        result = {}
        next_index = 0
        keyed = false

        items.each do |item|
          unless item.is_a?(Spread)
            result[next_index] = item
            next_index += 1
            next
          end

          each_item(item.value) do |key, value|
            if key.nil? || MappingKey.integer?(key)
              result[next_index] = value
              next_index += 1
            else
              keyed = true
              result[key] = value
            end
          end
        end

        keyed ? result : result.values
      end

      # Builds a mapping literal with spreads, as PHP builds an array: a spread
      # value's string keys are kept and its integer keys are renumbered after
      # the highest integer key so far, so {5: 'x', ...[1, 2]} is
      # {5: 'x', 6: 1, 7: 2}. Keys written in the literal are kept as they are.
      # A string holding a decimal integer, such as "5", is an integer key, as
      # PHP stores it as one.
      #
      # @param [Array<Hash, Spread>] segments the literal's pairs, with each
      #   spread as a Spread between them
      # @return [Hash]
      def self.mapping(*segments)
        result = {}
        next_index = nil

        segments.each do |segment|
          if segment.is_a?(Spread)
            each_pair(segment.value) do |key, item|
              if MappingKey.integer?(key)
                next_index ||= 0
                result[next_index] = item
                next_index += 1
              else
                result[key] = item
              end
            end
          else
            segment.each do |key, item|
              result[key] = item
              next unless MappingKey.integer?(key)

              # PHP continues after the highest integer key, even a negative one
              next_index = key.to_i + 1 if next_index.nil? || key.to_i >= next_index
            end
          end
        end

        result
      end

      # Yields what a spread adds to a sequence: the key and value of each pair
      # of a mapping or a filter result, and a nil key with each item of
      # anything else, which is splatted as Ruby splats it
      def self.each_item(value, &)
        case value
        when ::Hash, EnumerableHash
          value.each(&)
        else
          [*value].each { |item| yield nil, item }
        end
      end

      def self.each_pair(value, &)
        case value
        when nil
          nil
        when ::Hash, EnumerableHash
          value.each(&)
        when ::Array
          value.each_with_index { |item, index| yield index, item }
        else
          raise TypeError, "no implicit conversion of #{value.class} into Hash" unless value.respond_to?(:to_hash)

          value.to_hash.each(&)
        end
      end

      private_class_method :each_item, :each_pair

      def initialize(value)
        @value = value
      end

      def array?
        value.is_a?(Array) || value.is_a?(Range)
      end

      def hash?
        value.is_a?(Hash)
      end
    end
  end
end
