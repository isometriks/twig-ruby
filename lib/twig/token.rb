module Twig
  class Token
    EOF_TYPE = :eof
    TEXT_TYPE = :text
    BLOCK_START_TYPE = :block_start
    VAR_START_TYPE = :var_start
    BLOCK_END_TYPE = :block_end
    VAR_END_TYPE = :var_end
    NAME_TYPE = :name
    NUMBER_TYPE = :number
    STRING_TYPE = :string
    OPERATOR_TYPE = :operator
    PUNCTUATION_TYPE = :punctuation
    INTERPOLATION_START_TYPE = :interpolation_start
    INTERPOLATION_END_TYPE = :interpolation_end
    ARROW_TYPE = :arrow
    SPREAD_TYPE = :spread

    attr_reader :type, :value, :lineno

    def initialize(type, value, lineno)
      @type = type
      @value = value
      @lineno = lineno
    end

    def test(type, values = nil)
      if values.nil? && !type.is_a?(Symbol)
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
