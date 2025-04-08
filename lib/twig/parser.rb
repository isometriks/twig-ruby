# frozen_string_literal: true

module Twig
  # @!attribute [r] stream
  #   @return [TokenStream]
  class Parser
    attr_reader :stream, :block_stack

    # @return [Environment]
    attr_reader :environment

    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
    end

    # @param [TokenStream] stream
    def parse(stream, test = nil, drop_needle: false)
      @stream = stream
      @parent = nil
      @traits = AutoHash.new
      @macros = {}
      @blocks = {}
      @block_stack = []
      @imported_symbols = [{}]
      @ignore_unknown_twig_callables = false

      body = subparse(test, drop_needle:)

      Node::Module.new(
        Node::Body.new({ 0 => body }),
        @parent,
        @blocks.empty? ? Node::Empty.new : Node::Nodes.new(@blocks),
        @macros.empty? ? Node::Empty.new : Node::Nodes.new(@macros),
        @traits.empty? ? Node::Empty.new : Node::Nodes.new(@traits),
        stream.source
      )
    end

    # @param [Proc, nil] test
    # @return [Node::Base]
    def subparse(test, drop_needle: false)
      lineno = current_token.lineno
      rv = AutoHash.new

      until stream.eof?
        case current_token.type
        when Token::TEXT_TYPE
          token = stream.next
          rv.add(Node::Text.new(token.value, token.lineno))
        when Token::VAR_START_TYPE
          token = stream.next
          expr = expression_parser.parse_expression
          stream.expect(Token::VAR_END_TYPE)

          rv.add(Node::Print.new(expr, token.lineno))
        when Token::BLOCK_START_TYPE
          stream.next
          token = current_token

          unless token.type == Token::NAME_TYPE
            raise Error::Syntax.new('A block must start with a tag name.', token.lineno, stream.source)
          end

          if test&.call(token)
            stream.next if drop_needle
            return rv.values.first if rv.length == 1

            return Node::Nodes.new(rv, lineno)
          end

          # @todo Check that there is a token parser for this token value
          subparser = @environment.token_parser(token.value)

          unless subparser
            raise Error::Syntax.new("Unexpected '#{token.value}' tag.", token.lineno, stream.source)
          end

          stream.next
          subparser.parser = self
          node = subparser.parse(token)

          raise 'Cannot return nil from TokenParser' unless node

          node.tag = subparser.tag

          rv.add(node)
        else
          raise "Unable to parse token of type #{current_token.type}"
        end
      end

      Node::Nodes.new(rv)
    end

    def subparse_ignore_unknown_twig_callables(test, drop_needle: false)
      previous = @ignore_unknown_twig_callables
      @ignore_unknown_twig_callables = true

      begin
        subparse(test, drop_needle:)
      ensure
        @ignore_unknown_twig_callables = previous
      end
    end

    # @return [Token]
    def current_token
      stream.current
    end

    # @return [ExpressionParser]
    def expression_parser
      @expression_parser ||= ExpressionParser.new(self, @environment)
    end

    # @return [Boolean]
    def inheritance?
      @parent || @traits.length.positive?
    end

    def main_scope?
      @imported_symbols.one?
    end

    def push_local_scope
      @imported_symbols.unshift({})
    end

    def pop_local_scope
      @imported_symbols.shift
    end

    def add_imported_symbol(type, symbol_alias, name = nil, internal_ref = nil)
      @imported_symbols[0][type] ||= {}
      @imported_symbols[0][type][symbol_alias] = { name:, node: internal_ref }
    end

    def imported_symbol(type, symbol_alias)
      if (symbol = @imported_symbols.dig(0, type, symbol_alias))
        symbol
      else
        @imported_symbols.dig(-1, type, symbol_alias)
      end
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

    def add_trait(trait)
      @traits << trait
    end

    # @param [String] name
    # @param [Node::Macro] node
    def set_macro(name, node)
      @macros[name] = node
    end

    # @param [String] name
    # @param [Node::Body] value
    def set_block(name, value)
      if @blocks.key?(name)
        raise Error::Syntax.new(
          "The block \"#{name}\" has already been defined line #{@blocks[name].lineno}",
          current_token.lineno,
          @blocks[name].source_context
        )
      end

      @blocks[name] = Node::Body.new({ 0 => value }, {}, value.lineno)
    end

    # @param [Node::Base] parent
    def parent=(parent)
      if @parent
        raise Error::Syntax.new('Cannot extends twice', parent.lineno, parent.source_context)
      end

      @parent = parent
    end

    def ignore_unknown_twig_callables?
      @ignore_unknown_twig_callables
    end
  end
end
