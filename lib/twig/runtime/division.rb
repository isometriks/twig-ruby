# frozen_string_literal: true

module Twig
  module Runtime
    # The / operator, which divides integers the way PHP does instead of
    # truncating like Ruby's Integer#/
    module Division
      # An exact division of two integers stays an Integer and any other
      # division of them is a Float, so 8 / 2 is 4 and 7 / 2 is 3.5. Other
      # operands divide as Ruby does.
      #
      # @param [Object] left
      # @param [Object] right
      # @return [Object]
      def self.divide(left, right)
        return left / right unless left.is_a?(Integer) && right.is_a?(Integer)

        (left % right).zero? ? left / right : left.fdiv(right)
      end
    end
  end
end
