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

      # @param [Object] wrapped
      def initialize(wrapped)
        @wrapped = wrapped
      end

      def each(...)
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
    end
  end
end
