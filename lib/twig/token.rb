module Twig
  class Token
    EOF_TYPE = -1
    TEXT_TYPE = 0
    BLOCK_START_TYPE = 1
    VAR_START_TYPE = 2
    BLOCK_END_TYPE = 3
    VAR_END_TYPE = 4
    NAME_TYPE = 5
    NUMBER_TYPE = 6
    STRING_TYPE = 7
    OPERATOR_TYPE = 8
    PUNCTUATION_TYPE = 9
    INTERPOLATION_START_TYPE = 10
    INTERPOLATION_END_TYPE = 11
    ARROW_TYPE = 12
    SPREAD_TYPE = 13

    attr_reader :type, :value, :lineno

    def initialize(type, value, lineno)
      @type = type
      @value = value
      @lineno = lineno
    end

    def test(type, values = nil)
      if values.nil? && !type.is_a?(Integer)
        values = type
        type = NAME_TYPE
      end

      @type == type && (
        values.nil? ||
          (values.is_a?(Array) && values.include?(@value)) ||
          (@value == values)
      )
    end
  end
end
