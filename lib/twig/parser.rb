module Twig
  # @!attribute [r] stream
  #   @return [TokenStream]
  class Parser
    attr_reader :stream, :block_stack

    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
    end

    # @param [TokenStream] stream
    def parse(stream, test = nil, drop_needle: false)
      @stream = stream
      @blocks = {}
      @block_stack = []
      @imported_symbols = [{}]

      body = subparse(test, drop_needle:)

      Node::ModuleNode.new(body, Node::Nodes.new(@blocks), stream.source)
    end

    # @param [Proc] test
    # @return [Node::Base]
    def subparse(test, drop_needle: false)
      lineno = current_token.lineno
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
        when Token::BLOCK_START_TYPE
          stream.next
          token = current_token

          raise "A block must start with a tag name" unless token.type == Token::NAME_TYPE

          if test&.call(token)
            stream.next if drop_needle
            return rv.values.first if rv.length == 1
            return Node::Nodes.new(rv, lineno)
          end

          # @todo Check that there is a token parser for this token value
          subparser = @environment.token_parser(token.value)

          raise "Unexpected #{token.value} tag" unless subparser

          stream.next
          subparser.parser = self
          node = subparser.parse(token)

          raise "Cannot return nil from TokenParser" unless node
          node.tag = subparser.tag

          rv[rv.length] = node
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

    def push_local_scope
      @imported_symbols.unshift({})
    end

    def pop_local_scope
      @imported_symbols.shift
    end

    def peek_block_stack
      @block_stack[-1]
    end

    def pop_block_stack
      @block_stack.pop
    end

    def push_block_stack(name)
      @block_stack << name
    end

    def block?(name)
      @blocks.key?(name)
    end

    # @todo type value as BlockNode and also set it to a BodyNode
    def set_block(name, value)
      @blocks[name] = value
    end
  end
end
