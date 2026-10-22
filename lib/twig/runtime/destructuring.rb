# frozen_string_literal: true

module Twig
  module Runtime
    # Runtime support for destructuring assignments. PHP keeps this on
    # CoreExtension (destructureSequence); it lives here so destructuring
    # does not need to touch Extension::Core.
    module Destructuring
      # Assigns the items of value to the names, in order, as `[a, , b] = value`
      #
      # @param [Runtime::Context] context
      # @param [Array<String, nil>] names nil for an empty slot
      # @param [Object] value
      # @return [Object] the padded sequence for an Array, otherwise the value
      def self.sequence(context, names, value)
        case value
        when Array
          padded = value.length < names.length ? value + ::Array.new(names.length - value.length) : value
          assign(context, names) { |i| padded[i] }

          padded
        when Hash
          assign(context, names) { |i| value.key?(i) ? value[i] : value[i.to_s] }

          value
        else
          # PHP's array_pad fails on anything that is neither an array nor
          # Traversable, so a scalar or null is an error rather than nulls
          unless value.respond_to?(:each)
            raise Error::Runtime, "Sequence destructuring expects a sequence or a mapping, got \"#{value.class}\"."
          end

          each_item(context, names, value)

          value
        end
      end

      # Consumes no more items than there are names, so a lazy or one-shot
      # sequence is not iterated further than it needs to be
      def self.each_item(context, names, value)
        return if names.empty?

        i = 0
        each_value(value) do |item|
          context[names[i]] = item unless names[i].nil?
          i += 1
          break if i == names.length
        end

        names[i..].each { |name| context[name] = nil unless name.nil? }
      end

      # An EnumerableHash (what filter returns, for instance) yields key and
      # value pairs; take the value, as a for loop over it does
      def self.each_value(value, &)
        if value.is_a?(EnumerableHash)
          value.each { |_key, item| yield item } # rubocop:disable Style/HashEachMethods
        else
          value.each(&)
        end
      end

      def self.assign(context, names)
        names.each_with_index do |name, i|
          context[name] = yield(i) unless name.nil?
        end
      end

      private_class_method :each_item, :each_value, :assign
    end
  end
end
