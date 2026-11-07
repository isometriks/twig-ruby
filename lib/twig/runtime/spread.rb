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

      # Splits arguments into the positional and named arguments PHP 8.1
      # passes for them, unpacking each Spread as PHP unpacks an array or a
      # Traversable into a call: its integer keys, and quoted decimal keys
      # such as "0", are positional and its string keys are named. Raises
      # PHP's errors for a positional argument after a named one, for a name
      # given twice and for a value that isn't iterable.
      #
      # @param [Array<Object, Spread>, Hash{Integer, String, Symbol => Object}]
      #   arguments positional arguments and spreads, or a Hash of them keyed
      #   by position, with named arguments keyed by their name
      # @param [Boolean] overwrite whether a name given again replaces the
      #   value, as for a method call, whose arguments PHP gathers in an array
      #   before it unpacks them
      # @return [Array(Array, Hash{String => Object})]
      def self.split_arguments(arguments, overwrite: false)
        positional = []
        named = {}
        name = lambda do |key, value|
          if !overwrite && named.key?(key)
            raise ArgumentError, "Named parameter $#{key} overwrites previous argument"
          end

          named[key] = value
        end

        arguments = arguments.each_with_index.map { |value, index| [index, value] } if arguments.is_a?(::Array)

        arguments.each do |key, value|
          if value.is_a?(Spread)
            value.each_argument do |item_key, item|
              if item_key.nil?
                if named.any?
                  raise ArgumentError, 'Cannot use positional argument after named argument during unpacking'
                end

                positional << item
              else
                name.call(item_key, item)
              end
            end
          elsif MappingKey.integer?(key)
            raise ArgumentError, 'Cannot use positional argument after named argument during unpacking' if named.any?

            positional << value
          else
            name.call(key.to_s, value)
          end
        end

        [positional, named]
      end

      # Yields what a spread adds to a sequence: the key and value of each pair
      # of a mapping or a filter result, and the position of each item of
      # anything else that is iterable
      def self.each_item(value, &)
        value = value.to_hash if !value.is_a?(::Hash) && value.respond_to?(:to_hash)

        case value
        when ::Hash, EnumerableHash
          value.each(&)
        else
          new(value).each_argument { |_, item| yield nil, item }
        end
      end

      def self.each_pair(value, &)
        value = value.to_hash if !value.is_a?(::Hash) && value.respond_to?(:to_hash)

        case value
        when ::Hash, EnumerableHash
          value.each(&)
        else
          index = -1
          new(value).each_argument { |_, item| yield index += 1, item }
        end
      end

      private_class_method :each_item, :each_pair

      def initialize(value)
        @value = value
      end

      # Splits the value into the positional and named arguments PHP 8.1
      # unpacks from it, raising PHP's error for a positional argument after a
      # named one
      #
      # @return [Array(Array, Hash{String => Object})]
      def arguments
        self.class.split_arguments([self])
      end

      # Yields each argument PHP 8.1 unpacks from the value, with nil as the
      # name of a positional one. A Hash or a filter result is walked pair by
      # pair: an integer key, or a quoted decimal key such as "0", which PHP
      # stores as an integer, is positional, and a string or symbol key is a
      # name. Any other Enumerable (a sequence, a range, a Set, an Enumerator)
      # is positional. Anything else raises the TypeError PHP raises.
      #
      # @yieldparam [String, nil] name
      # @yieldparam [Object] item
      def each_argument
        pairs = value.respond_to?(:to_hash) ? value.to_hash : value

        if pairs.is_a?(::Hash) || pairs.is_a?(EnumerableHash)
          pairs.each do |key, item|
            if MappingKey.integer?(key)
              yield nil, item
            elsif key.is_a?(String) || key.is_a?(Symbol)
              yield key.to_s, item
            else
              raise TypeError, 'Keys must be of type int|string during argument unpacking'
            end
          end
        elsif value.is_a?(Enumerable)
          value.each { |item| yield nil, item }
        else
          raise TypeError, 'Only arrays and Traversables can be unpacked'
        end
      end
    end
  end
end
