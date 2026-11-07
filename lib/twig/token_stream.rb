# frozen_string_literal: true

module Twig
  # @!attribute [r] source
  #   @return [Source]
  class TokenStream
    # @return [Array<Token>]
    attr_reader :tokens

    # @return [Source]
    attr_reader :source

    # @param [Array<Token>] tokens
    # @param [Source] source
    def initialize(tokens, source)
      @tokens = tokens
      @source = source
      @current = 0
    end

    # @return [Token]
    def next
      @current += 1

      unless tokens[@current]
        raise Error::Syntax.new('Unexpected end of template.', tokens[@current - 1].lineno, source)
      end

      tokens[@current - 1]
    end

    # @return [Token]
    def current
      tokens[@current]
    end

    # @return [Token]
    def expect(type, value = nil, message = nil)
      token = current

      unless token.test(type, value)
        expected = Token.type_to_english(type)
        unexpected = Token.type_to_english(token.type)
        token_value = shown?(token.value) ? " of value \"#{token.value}\"" : ''
        value = shown?(value) ? " with value \"#{value}\"" : nil
        message = "#{message}. " if message

        raise Error::Syntax.new(
          "#{message}Unexpected token \"#{unexpected}\"#{token_value} (\"#{expected}\" expected#{value}).",
          token.lineno,
          source,
          column: source&.column(token.offset)
        )
      end

      self.next

      token
    end

    # @param [Integer] number
    # @return [Token]
    def look(number = 1)
      unless tokens.length >= @current + number
        raise Error::Syntax.new('Unexpected end of template.', tokens[@current].lineno, source)
      end

      tokens[@current + number]
    end

    def test(primary, secondary = nil)
      current.test(primary, secondary)
    end

    def next_if(primary, secondary = nil)
      current.test(primary, secondary) ? self.next : nil
    end

    # Replaces the current token, for a parser that reads it differently
    # from the lexer.
    #
    # @param [Token] token
    def replace_current(token)
      tokens[@current] = token
    end

    def eof?
      current.type == Token::EOF_TYPE
    end

    def debug
      tokens.
        map(&:debug).
        map { |type, value| "#{type}(#{value})" }
    end

    # @param [Array<Token>] tokens
    def inject(tokens)
      @tokens.insert(@current, *tokens)
    end

    private

    # Twig leaves a value out of an error when it is falsy in PHP, as 0, 0.0,
    # "0" and "" are.
    def shown?(value)
      !(value.nil? || value == false || value == '' || value == '0' || (value.is_a?(Numeric) && value.zero?))
    end
  end
end
