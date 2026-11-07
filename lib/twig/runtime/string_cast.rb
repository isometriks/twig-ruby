# frozen_string_literal: true

module Twig
  module Runtime
    # How a value becomes a string when it is printed or concatenated, which
    # for a float is PHP's (string) cast rather than Ruby's Float#to_s
    module StringCast
      # The significant digits PHP's precision setting gives a float, 14 by
      # default
      PRECISION = 14

      # @param [Object] value
      # @return [String]
      def self.cast(value)
        value.is_a?(Float) ? float(value) : value.to_s
      end

      # Formats a float as PHP does: with up to 14 significant digits and
      # without a trailing .0, so 1.0 is "1" and 0.1 + 0.2 is "0.3", in
      # exponent form such as "1.0E+15" when it is very large or small, and
      # INF, -INF and NAN for the values that aren't finite
      #
      # @param [Float] value
      # @return [String]
      def self.float(value)
        return 'NAN' if value.nan?
        return value.positive? ? 'INF' : '-INF' if value.infinite?
        return (1.0 / value).negative? ? '-0' : '0' if value.zero?

        mantissa, exponent = format("%.#{PRECISION - 1}e", value.abs).split('e')
        exponent = exponent.to_i
        digits = mantissa.delete('.').sub(/0+\z/, '')
        sign = value.negative? ? '-' : ''

        "#{sign}#{place_point(digits, exponent)}"
      end

      # Writes digits, the first of which is at the given power of ten, as
      # zend_gcvt does
      def self.place_point(digits, exponent)
        if exponent < -4 || exponent >= PRECISION
          fraction = digits[1..]
          "#{digits[0]}.#{fraction.empty? ? '0' : fraction}E#{exponent.negative? ? '-' : '+'}#{exponent.abs}"
        elsif exponent.negative?
          "0.#{'0' * (-exponent - 1)}#{digits}"
        elsif digits.length <= exponent + 1
          digits.ljust(exponent + 1, '0')
        else
          "#{digits[0..exponent]}.#{digits[(exponent + 1)..]}"
        end
      end

      private_class_method :place_point
    end
  end
end
