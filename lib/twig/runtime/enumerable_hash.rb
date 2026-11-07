# frozen_string_literal: true

module Twig
  module Runtime
    class EnumerableHash
      include Enumerable

      MISSING_KEY = "__§__missing_key_#{rand}".freeze

      private_constant :MISSING_KEY

      def self.from(object)
        if object.is_a?(Array)
          new(AutoHash.new.add(*object))
        elsif object.is_a?(Hash)
          new(object.to_h)
        else
          new(object)
        end
      end

      # Reads an Enumerable as PHP reads a Traversable, by what it yields: an
      # item yielded on its own, even an Array such as a pair of a Set or of
      # [[1, 2]].each, is a value keyed by its position, and a key and a
      # value yielded together are a pair. An Array, a Hash or a filter
      # result is read as from reads it.
      def self.traversable(object)
        return from(object) if object.is_a?(Array) || object.is_a?(Hash) || object.is_a?(EnumerableHash)

        new(object, by_position: true)
      end

      # @param [Object] wrapped
      # @param [Boolean] by_position whether an Array yielded on its own is an
      #   item, rather than a key and a value
      def initialize(wrapped, by_position: false)
        @wrapped = wrapped
        @by_position = by_position
      end

      def each(...)
        return each_by_position(...) if @by_position

        key = 0
        @wrapped&.each do |k, v = MISSING_KEY| # rubocop:disable Style/HashEachMethods
          if v == MISSING_KEY
            yield(key, k)
            key += 1
          else
            yield(k, v)
          end
        end
      end

      def values
        collect { |_, v| v }
      end

      def keys
        collect { |k, _| k }
      end

      def filter
        self.class.new(super)
      end

      # The array PHP's iterator_to_array makes of a Traversable: its pairs,
      # as an Array when the keys are 0, 1, 2... in order, as PHP calls such
      # an array a list, or else as a Hash. Without preserve_keys, the values.
      #
      # @return [Array, Hash]
      def to_array(preserve_keys: true)
        return values unless preserve_keys

        hash = to_h
        list = hash.each_key.with_index.all? { |key, index| key.is_a?(Integer) && key == index }

        list ? hash.values : hash
      end

      private

      def each_by_position
        key = 0
        @wrapped.each do |*item|
          if item.length > 1
            yield(item[0], item[1])
          else
            yield(key, item[0])
            key += 1
          end
        end
      end
    end
  end
end
