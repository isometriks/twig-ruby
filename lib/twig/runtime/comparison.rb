# frozen_string_literal: true

module Twig
  module Runtime
    # The ==, !=, <, >, <=, >= and <=> operators, which compare values the way
    # PHP 8 does instead of with Ruby's operators, as does Twig's
    # CoreExtension::compare
    module Comparison
      # The whitespace PHP allows around a numeric string
      WHITESPACE = " \t\n\r\v\f"
      # A string PHP reads as an integer
      INTEGER = /\A[#{WHITESPACE}]*[+-]?\d+[#{WHITESPACE}]*\z/
      # A string PHP reads as a number
      NUMERIC = /\A[#{WHITESPACE}]*[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?[#{WHITESPACE}]*\z/
      INT_MAX = (2**63) - 1
      INT_MIN = -(2**63)

      private_constant :WHITESPACE, :INTEGER, :NUMERIC, :INT_MAX, :INT_MIN

      # Compares two values as PHP's <=> does and returns -1, 0 or 1:
      # - numbers and numeric strings compare as numbers, so 2 < "10", and
      #   other strings compare byte by byte, a number against one as its
      #   string;
      # - null against a string is "", and null or a boolean against anything
      #   else compares as booleans, so null == 0 and null < 1, with Markup
      #   true as an object;
      # - arrays compare by size and then element by element, and an array is
      #   greater than any other value;
      # - two values that can't be compared, such as mappings with different
      #   keys, give 1.
      # Other objects are equal when Ruby's == says so and ordered by <=>.
      #
      # @param [Object] left
      # @param [Object] right
      # @return [Integer]
      def self.compare(left, right)
        left = normalize(left)
        right = normalize(right)

        if left.is_a?(String) && right.is_a?(String)
          compare_strings(left, right)
        elsif left.nil? && right.is_a?(String)
          right.empty? ? 0 : -1
        elsif left.is_a?(String) && right.nil?
          left.empty? ? 0 : 1
        elsif boolean?(left) || boolean?(right)
          threeway(Truthiness.cast?(left) ? 1 : 0, Truthiness.cast?(right) ? 1 : 0)
        elsif number?(left) && number?(right)
          compare_numbers(left, right)
        elsif number?(left) && right.is_a?(String)
          compare_number_to_string(left, right)
        elsif left.is_a?(String) && number?(right)
          right.is_a?(Float) && right.nan? ? 1 : -compare_number_to_string(right, left)
        elsif array?(left) && array?(right)
          compare_arrays(left, right)
        elsif array?(left)
          1
        elsif array?(right)
          -1
        else
          compare_objects(left, right)
        end
      end

      # @return [Boolean] Whether left == right in PHP
      def self.equal?(left, right)
        compare(left, right).zero?
      end

      # @return [Boolean] Whether left != right in PHP
      def self.not_equal?(left, right)
        !equal?(left, right)
      end

      # @return [Boolean] Whether left < right in PHP
      def self.less?(left, right)
        compare(left, right).negative?
      end

      # @return [Boolean] Whether left <= right in PHP
      def self.less_equal?(left, right)
        compare(left, right) <= 0
      end

      # PHP evaluates left > right as right < left, which differs from
      # !(left <= right) for values that can't be compared, such as NAN
      #
      # @return [Boolean] Whether left > right in PHP
      def self.greater?(left, right)
        less?(right, left)
      end

      # @return [Boolean] Whether left >= right in PHP
      def self.greater_equal?(left, right)
        less_equal?(right, left)
      end

      # The largest of values as PHP's max(a, b, ...) finds it
      def self.max(values)
        values.drop(1).reduce(values.first) { |max, value| compare(value, max).positive? ? value : max }
      end

      # The smallest of values as PHP's min(a, b, ...) finds it
      def self.min(values)
        values.drop(1).reduce(values.first) { |min, value| compare(value, min).negative? ? value : min }
      end

      # The largest element of an array as PHP's max(array) finds it, which
      # compares the other way round from max(a, b, ...)
      def self.max_of(values)
        values.drop(1).reduce(values.first) { |max, value| compare(max, value).negative? ? value : max }
      end

      # The smallest element of an array as PHP's min(array) finds it
      def self.min_of(values)
        values.drop(1).reduce(values.first) { |min, value| compare(min, value).positive? ? value : min }
      end

      # Sorts values as PHP's stable sort does with this comparison
      #
      # @param [Array] values
      # @return [Array]
      def self.sort(values, &by)
        by ||= :itself.to_proc

        values.each_with_index.sort do |(left, left_index), (right, right_index)|
          result = compare(by.call(left), by.call(right))
          result.zero? ? left_index <=> right_index : result
        end.map(&:first)
      end

      def self.normalize(value)
        case value
        when Symbol
          value.to_s
        when ::Range, Enumerator::ArithmeticSequence
          value.to_a
        else
          value
        end
      end

      def self.boolean?(value)
        value.nil? || value == true || value == false
      end

      def self.number?(value)
        value.is_a?(Integer) || value.is_a?(Float)
      end

      def self.array?(value)
        value.is_a?(Array) || value.is_a?(Hash) || value.is_a?(EnumerableHash)
      end

      def self.threeway(left, right)
        if left == right
          0
        else
          left < right ? -1 : 1
        end
      end

      def self.compare_numbers(left, right)
        return threeway(left, right) if left.is_a?(Integer) && right.is_a?(Integer)

        threeway(left.to_f, right.to_f)
      end

      def self.compare_number_to_string(number, string)
        return 1 if number.is_a?(Float) && number.nan?

        parsed = parse_number(string)

        if parsed.nil?
          threeway(StringCast.cast(number).b, string.b)
        elsif number.is_a?(Integer) && parsed.first.is_a?(Integer)
          threeway(number, parsed.first)
        else
          threeway(number.to_f, parsed.first.to_f)
        end
      end

      # zendi_smart_strcmp: numeric strings compare as numbers, unless both
      # are integers too big for PHP that round to the same float
      def self.compare_strings(left, right)
        left_number = parse_number(left)
        right_number = parse_number(right)

        return threeway(left.b, right.b) if left_number.nil? || right_number.nil?

        (left_value, left_overflow) = left_number
        (right_value, right_overflow) = right_number

        if left_overflow != 0 && left_overflow == right_overflow && left_value == right_value
          return threeway(left.b, right.b)
        end

        if left_value.is_a?(Integer) && right_value.is_a?(Integer)
          threeway(left_value, right_value)
        elsif left_value.is_a?(Integer)
          right_overflow.zero? ? normalize_float(left_value - right_value) : -right_overflow
        elsif right_value.is_a?(Integer)
          left_overflow.zero? ? normalize_float(left_value - right_value) : left_overflow
        elsif left_value == right_value && !left_value.finite?
          threeway(left.b, right.b)
        else
          normalize_float(left_value - right_value)
        end
      end

      def self.normalize_float(value)
        if value.positive?
          1
        else
          value.negative? ? -1 : 0
        end
      end

      # Reads a string as PHP's is_numeric_string does, as an Integer, or a
      # Float with the sign of the overflow when it is an integer PHP can't
      # hold, or nil when it isn't numeric
      #
      # @return [Array(Numeric, Integer), nil]
      def self.parse_number(string)
        string = string.b

        if INTEGER.match?(string)
          integer = string.strip.to_i
          return [integer, 0] if integer.between?(INT_MIN, INT_MAX)

          [integer.to_f, integer.positive? ? 1 : -1]
        elsif NUMERIC.match?(string)
          [string.strip.to_f, 0]
        end
      end

      def self.compare_arrays(left, right)
        left = pairs(left)
        right = pairs(right).to_h
        return threeway(left.size, right.size) unless left.size == right.size

        left.each do |key, value|
          return 1 unless right.key?(key)

          result = compare(value, right[key])
          return result unless result.zero?
        end

        0
      end

      # The key and value pairs of an array, with keys as PHP casts them
      def self.pairs(array)
        case array
        when Array
          array.each_with_index.map { |value, index| [index, value] }
        else
          array.map do |key, value|
            key = key.to_s if key.is_a?(Symbol)
            key = key.to_i if key.is_a?(String) && MappingKey.integer?(key)

            [key, value]
          end
        end
      end

      # Objects are equal when Ruby's == says so, and otherwise ordered by
      # <=>, unless it can't order them or calls them equal while == doesn't,
      # as an unsaved ActiveRecord model's <=> does with any other
      def self.compare_objects(left, right)
        return 0 if left == right

        result = left <=> right
        result.is_a?(Integer) && !result.zero? ? threeway(result, 0) : 1
      end

      private_class_method :normalize, :boolean?, :number?, :array?, :threeway, :compare_numbers,
        :compare_number_to_string, :compare_strings, :normalize_float, :parse_number,
        :compare_arrays, :pairs, :compare_objects
    end
  end
end
