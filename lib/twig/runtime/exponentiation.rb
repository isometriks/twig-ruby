# frozen_string_literal: true

module Twig
  module Runtime
    # The ** operator, which raises numbers to a power the way PHP does instead
    # of giving Ruby's Rational or Complex results
    module Exponentiation
      # An integer raised to a negative integer is a Float, so 2 ** -1 is 0.5,
      # and a power with no real result is NaN, as (-8) ** 0.5 is in PHP. Other
      # operands raise to a power as Ruby does, so 2 ** 3 is still the Integer 8.
      #
      # @param [Object] base
      # @param [Object] exponent
      # @return [Object]
      def self.power(base, exponent)
        if base.is_a?(Integer) && exponent.is_a?(Integer) && exponent.negative?
          return base.to_f**exponent
        end

        result = base**exponent

        if result.is_a?(Complex) && !base.is_a?(Complex) && !exponent.is_a?(Complex)
          Float::NAN
        else
          result
        end
      end
    end
  end
end
