module Twig
  # @!attribute [r] source
  #   @return [Source]
  class TokenStream
    attr_reader :tokens, :source

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

      raise "Unexpected end of template." unless @tokens[@current]

      @tokens[@current - 1]
    end

    # @return [Token]
    def current
      @tokens[@current]
    end

    # @return [Token]
    def expect(type, value = nil, message = nil)
      token = current

      unless token.test(type, value)
        raise "Expected #{type} but got #{token.type} #{message}"
      end

      self.next

      token
    end

    def test(primary, secondary)
      current.test(primary, secondary)
    end

    def next_if(primary, secondary = nil)
      current.test(primary, secondary) ? self.next : nil
    end

    def eof?
      current.type == Token::EOF_TYPE
    end

    def debug
      lines = []

      tokens.each do |token|
        lines << token.debug
      end

      lines.map { |type, value| "#{type}(#{value})" }.join("\n")
    end
  end
end
