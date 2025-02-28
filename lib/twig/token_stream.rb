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
        raise Error::Syntax.new(
          "Expected #{type}(#{value}) but got #{token.type}(#{token.value}) #{message}".rstrip,
          token.lineno,
          source
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

    def eof?
      current.type == Token::EOF_TYPE
    end

    def debug
      tokens.
        map(&:debug).
        map { |type, value| "#{type}(#{value})" }
    end
  end
end
