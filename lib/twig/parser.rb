module Twig
  class Parser
    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
    end

    # @param [TokenStream] stream
    def parse(stream, test = nil, drop_needle = false)
      @stream = stream

      body = subparse(test, drop_needle)
    end

    # @return [Node::Node]
    def subparse(test, drop_needle = false)
      lineno = current_token.lineno
      rv = []

      until stream.eof?
        case current_token.type
        when Token::TEXT_TYPE
          token = stream.next
          rv << Node::TextNode.new(token.value, token.lineno)
        when Token::VAR_START_TYPE
          token = stream.next
          var_name = stream.next.value
          rv << Node::TextNode.new("{{ variable: #{var_name} }}", current_token.lineno)
          stream.expect(Token::VAR_END_TYPE)
        else
          raise "Unable to parse token of type #{current_token.type}"
        end
      end

      Node::Node.new(rv)
    end

    private

    # @return [TokenStream]
    def stream
      @stream
    end

    # @return [Token]
    def current_token
      @stream.current
    end
  end
end
