module Twig
  class TokenStream
    attr_reader :tokens

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
        raise "Expected #{type} but got #{token.type}"
      end

      self.next

      token
    end

    def eof?
      current.type == Token::EOF_TYPE
    end
  end
end
