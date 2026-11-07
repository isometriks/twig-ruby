# frozen_string_literal: true

module Twig
  module Runtime
    # How a value becomes a string when it is printed or concatenated, which
    # for a float is PHP's (string) cast rather than Ruby's Float#to_s
    module StringCast
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
        Util::PhpSprintf.float_to_string(value)
      end
    end
  end
end
