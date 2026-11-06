# frozen_string_literal: true

module Twig
  # @!attribute [r] stream
  #   @return [TokenStream]
  class Parser
    attr_reader :stream, :block_stack

    # @return [Environment]
    attr_reader :environment

    STACKABLE = %i[
      stream
      parent
      blocks
      block_stack
      macros
      imported_symbols
      traits
      embedded_templates
      ignore_unknown_twig_callables
    ].freeze

    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
      @parsers = environment.expression_parsers
      @stack = []
    end

    # @param [TokenStream] stream
    # @return [Node::Module]
    def parse(stream, test = nil, drop_needle: false)
      # Save the current value to stack
      frame = {}
      STACKABLE.each do |attr|
        frame[attr] = instance_variable_get("@#{attr}")
      end

      @stack << frame
      @stream = stream
      @parent = nil
      @traits = AutoHash.new
      @macros = {}
      @blocks = {}
      @embedded_templates = AutoHash.new
      @block_stack = []
      @imported_symbols = [{}]
      @ignore_unknown_twig_callables = false

      begin
        body = subparse(test, drop_needle:)
        body = cleanup_body_for_child_templates(body) if @parent
      rescue Error::Syntax => e
        unless e.source_context
          e.source_context = stream.source
        end

        unless e.lineno
          e.lineno = stream.current.lineno
        end

        raise e
      end

      node = Node::Module.new(
        Node::Body.new({ 0 => body }),
        @parent,
        @blocks.empty? ? Node::Empty.new : Node::Nodes.new(@blocks),
        @macros.empty? ? Node::Empty.new : Node::Nodes.new(@macros),
        @traits.empty? ? Node::Empty.new : Node::Nodes.new(@traits),
        @embedded_templates.empty? ? Node::Empty.new : Node::Nodes.new(@embedded_templates),
        stream.source
      )

      @visitors ||= environment.node_visitors

      node = NodeTraverser.
        new(environment, @visitors).
        traverse(node)

      # Restore stack
      frame = @stack.pop
      STACKABLE.each do |attr|
        instance_variable_set("@#{attr}", frame[attr])
      end

      node
    end

    # @param [Method, nil] test
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
          expr = parse_expression
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

          subparser = @environment.token_parser(token.value)

          unless subparser
            if test.nil?
              e = Error::Syntax.new("Unknown \"#{token.value}\" tag.", token.lineno, stream.source)
              e.add_suggestions(token.value, environment.token_parsers.keys)
            else
              e = Error::Syntax.new("Unexpected \"#{token.value}\" tag", token.lineno, stream.source)

              if test.respond_to?(:receiver) && (receiver = test.receiver) && receiver.is_a?(Twig::TokenParser::Base)
                e.append_message(
                  " (expecting closing tag for the \"#{receiver.tag}\" tag defined near line #{lineno})."
                )
              end
            end

            raise e
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

      return rv.values.first if rv.length == 1

      Node::Nodes.new(rv)
    end

    # Parses a discarded part of the template: what it registers (parent,
    # blocks, macros, ...) is discarded as well.
    def subparse_ignore_unknown_twig_callables(test, drop_needle: false)
      previous = @ignore_unknown_twig_callables
      # Ruby hashes are mutated in place, so copy what the subparse can register into
      state = [
        @parent,
        @blocks.dup,
        @macros.dup,
        @imported_symbols.map { |scope| scope.transform_values(&:dup) },
        @traits.dup,
        @embedded_templates.dup,
      ]
      @ignore_unknown_twig_callables = true

      begin
        subparse(test, drop_needle:)
      ensure
        @ignore_unknown_twig_callables = previous
        @parent, @blocks, @macros, @imported_symbols, @traits, @embedded_templates = state
      end
    end

    # @return [Token]
    def current_token
      stream.current
    end

    def parse_expression(precedence = 0)
      token = current_token
      if token.test(Token::OPERATOR_TYPE) && (parser = parsers.by_name(:prefix, token.value))
        stream.next
        expr = parser.parse(self, token)
      else
        expr = parsers.by_class(ExpressionParser::Prefix::Literal.name).parse(self, token)
      end

      token = current_token
      while token.test(Token::OPERATOR_TYPE) &&
            (parser = parsers.by_name(:infix, token.value)) &&
            parser.precedence >= precedence

        stream.next
        expr = parser.parse(self, expr, token)
        token = current_token
      end

      expr
    end

    # @return [TwigFilter]
    def filter(name, lineno)
      unless (filter = lookup_callable(:filter, name))
        unless ignore_unknown_twig_callables?
          e = Error::Syntax.new("Unknown \"#{name}\" filter.", lineno, stream.source)
          e.add_suggestions(name, environment.filters.keys)

          raise e
        end

        filter = TwigFilter.new(name, -> {})
      end

      filter
    end

    # @return [TwigFunction, Node::Expression::HelperMethod]
    def function(name, args, lineno)
      unless (function = lookup_callable(:function, name))
        if ignore_unknown_twig_callables?
          return TwigFunction.new(name, -> {})
        elsif environment.allow_helper_methods?
          return Node::Expression::HelperMethod.new(name, args, lineno)
        else
          e = Error::Syntax.new("Unknown \"#{name}\" function.", lineno, stream.source)
          e.add_suggestions(name, environment.functions.keys)

          raise e
        end
      end

      function
    end

    # @param [Integer] line
    # @return [TwigTest]
    def test(line)
      name = stream.expect(Token::NAME_TYPE).value

      if stream.test(Token::NAME_TYPE)
        # try 2 word tests
        name = "#{name} #{current_token.value}"

        test = lookup_callable(:test, name)
        stream.next
      else
        test = lookup_callable(:test, name)
      end

      if test.nil? && ignore_unknown_twig_callables?
        test = TwigTest.new(name, -> {})
      end

      unless test
        e = Error::Syntax.new("Unknown \"#{name}\" test.", line, stream.source)
        e.add_suggestions(name, environment.tests.keys)

        raise e
      end

      test
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

    # @param [Node::Module] template
    def embed_template(template)
      template.index = rand(2**32)

      @embedded_templates << template
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
      if @macros.key?(name)
        raise Error::Syntax.new(
          "Macro \"#{name}\" is defined twice (first definition at line #{@macros[name].lineno}).",
          node.lineno,
          node.source_context || stream.source
        )
      end

      @macros[name] = node
    end

    # @param [String] name
    # @param [Node::Body] value
    def set_block(name, value)
      if @blocks.key?(name)
        raise Error::Syntax.new(
          "The block '#{name}' has already been defined line #{@blocks[name].lineno}.",
          current_token.lineno,
          @blocks[name].source_context
        )
      end

      @blocks[name] = Node::Body.new({ 0 => value }, {}, value.lineno)
    end

    # @param [Node::Base] parent
    # @param [Boolean] throw_on_multiple
    def set_parent(parent, throw_on_multiple: true)
      if @parent
        return unless throw_on_multiple

        raise Error::Syntax.new(
          'Multiple extends tags are forbidden.',
          parent.lineno,
          parent.source_context || stream.source
        )
      end

      @parent = parent
    end

    # @param [Node::Base] parent
    def parent=(parent)
      set_parent(parent)
    end

    def ignore_unknown_twig_callables?
      @ignore_unknown_twig_callables
    end

    private

    # @return [ExpressionParser::ExpressionParsers]
    attr_reader :parsers

    # An undefined callable callback may raise a syntax error for a name it
    # knows is missing; while unknown callables are ignored (in a guard tag's
    # discarded branch) treat that the same as an unknown name.
    #
    # @param [Symbol] kind :filter, :function or :test
    def lookup_callable(kind, name)
      environment.public_send(kind, name)
    rescue Error::Syntax
      raise unless ignore_unknown_twig_callables?

      nil
    end

    # The correctness node visitor checks that a child template only has
    # content inside blocks; drop what is left that would never be output.
    def cleanup_body_for_child_templates(body)
      if body.is_a?(Node::BlockReference) || (body.is_a?(Node::Text) && body.blank?)
        return Node::Empty.new
      end

      body.nodes.delete_if do |_k, node|
        # as it has a parent, the block reference won't be used
        node.is_a?(Node::BlockReference) ||
          # remove nodes considered as "empty"
          (node.is_a?(Node::Text) && node.blank?)
      end

      body
    end
  end
end
