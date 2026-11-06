# frozen_string_literal: true

module Twig
  module Runtime
    class EnumerableHash
      include Enumerable

      MISSING_KEY = "__§__missing_key_#{rand}".freeze

      private_constant :MISSING_KEY

      def self.from(object)
        if object.is_a?(Array)
          new(AutoHash.new.add(*object), keyed: true)
        elsif object.is_a?(Hash)
          new(object.to_h, keyed: true)
        else
          new(object)
        end
      end

      # @param [Object] wrapped
      # @param [Boolean] keyed whether it came from an Array or a Hash, whose
      #   keys PHP keeps for an array, rather than from any other enumerable,
      #   which PHP reads as a Traversable, by position
      def initialize(wrapped, keyed: false)
        @wrapped = wrapped
        @keyed = keyed
      end

      def keyed?
        @keyed
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
        self.class.new(super, keyed: @keyed)
      end
    end
  end
end
