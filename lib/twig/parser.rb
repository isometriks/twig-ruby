module Twig
  # @!attribute [r] stream
  #   @return [TokenStream]
  class Parser
    attr_reader :stream

    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
    end

    # @param [TokenStream] stream
    def parse(stream, test = nil, drop_needle = false)
      @stream = stream

      body = subparse(test, drop_needle)

      Node::ModuleNode.new(body, stream.source)
    end

    # @return [Node::Node]
    def subparse(test, drop_needle = false)
      #lineno = current_token.lineno
      rv = {}

      until stream.eof?
        case current_token.type
        when Token::TEXT_TYPE
          token = stream.next
          rv[rv.length] = Node::TextNode.new(token.value, token.lineno)
        when Token::VAR_START_TYPE
          token = stream.next
          expr = expression_parser.parse_expression
          stream.expect(Token::VAR_END_TYPE)

          rv[rv.length] = Node::PrintNode.new(expr, token.lineno)
        else
          raise "Unable to parse token of type #{current_token.type}"
        end
      end

      Node::Nodes.new(rv)
    end

    # @return [Token]
    def current_token
      stream.current
    end

    # @return [ExpressionParser]
    def expression_parser
      @expression_parser ||= ExpressionParser.new(self, @environment)
    end
  end
end
