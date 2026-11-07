# frozen_string_literal: true

module Twig
  module Runtime
    # Whether a value is true in a condition, which Twig decides with PHP's
    # (bool) cast rather than Ruby's truthiness
    module Truthiness
      # nil, false, zero, the strings "" and "0", and an empty sequence or
      # mapping are false, and anything else is true. Markup is read as its
      # string, as Twig's TrueTest does, so a SafeBuffer holding "0" is false.
      # PHP objects are always true, so any other object is true, even one
      # that is empty or zero.
      #
      # @param [Object] value
      # @return [Boolean]
      def self.true?(value)
        case value
        when nil, false then false
        when String then !(value.empty? || value == '0')
        when Numeric then !value.zero?
        when Array, Hash then !value.empty?
        when EnumerableHash then value.any? { true }
        else true
        end
      end

      # PHP's plain (bool) cast, which array_filter, the loops of find, has
      # some and has every, and for ... if apply without Twig's TrueTest.
      # Markup is an object there, so an html_safe string such as a captured
      # "0" is true. The escape filter's output is a plain string in Twig,
      # so it is cast as one.
      #
      # @param [Object] value
      # @return [Boolean]
      def self.cast?(value)
        return true if value.is_a?(String) && value.html_safe? && !value.is_a?(Escaped)

        true?(value)
      end
    end
  end
end
