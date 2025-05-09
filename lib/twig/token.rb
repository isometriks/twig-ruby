# frozen_string_literal: true

module Twig
  class Token
    EOF_TYPE = :eof
    TEXT_TYPE = :text
    BLOCK_START_TYPE = :block_start
    VAR_START_TYPE = :var_start
    BLOCK_END_TYPE = :block_end
    VAR_END_TYPE = :var_end
    NAME_TYPE = :name
    SYMBOL_TYPE = :symbol
    CLASS_VAR_TYPE = :class_var
    NUMBER_TYPE = :number
    STRING_TYPE = :string
    OPERATOR_TYPE = :operator
    PUNCTUATION_TYPE = :punctuation
    INTERPOLATION_START_TYPE = :interpolation_start
    INTERPOLATION_END_TYPE = :interpolation_end
    ARROW_TYPE = :arrow
    SPREAD_TYPE = :spread

    TOKEN_TO_ENGLISH = {
      EOF_TYPE => 'end of template',
      TEXT_TYPE => 'text',
      BLOCK_START_TYPE => 'begin of statement block',
      VAR_START_TYPE => 'begin of print statement',
      BLOCK_END_TYPE => 'end of statement block',
      VAR_END_TYPE => 'end of print statement',
      NAME_TYPE => 'name',
      NUMBER_TYPE => 'number',
      STRING_TYPE => 'string',
      OPERATOR_TYPE => 'operator',
      PUNCTUATION_TYPE => 'punctuation',
      INTERPOLATION_START_TYPE => 'begin of string interpolation',
      INTERPOLATION_END_TYPE => 'end of string interpolation',
      SYMBOL_TYPE => 'symbol',
    }.freeze

    attr_reader :type, :value, :lineno

    def initialize(type, value, lineno)
      @type = type
      @value = value
      @lineno = lineno
    end

    # @param [Symbol | String] type
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

    def debug
      [type, value]
    end

    def self.type_to_english(type)
      TOKEN_TO_ENGLISH.fetch(type) do
        raise ArgumentError, "Token of type \"#{type}\" does not exist."
      end
    end
  end
end
