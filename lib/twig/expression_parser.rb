module Twig
  # @!attribute [r] environment
  #   @return [Environment]
  class ExpressionParser
    attr_reader :environment

    OPERATOR_LEFT = 1
    OPERATOR_RIGHT = 2

    # @param [Parser] parser
    # @param [Environment] environment
    def initialize(parser, environment)
      @parser = parser
      @environment = environment
    end

    # @return [Node::Expression::Base]
    def parse_expression(precedence = 0)
      # @todo parse arrow

      expr = get_primary
      token = parser.current_token

      while binary?(token) && binary_operators[token.value.to_sym][:precedence] >= precedence
        operator = binary_operators[token.value.to_sym]
        parser.stream.next

        next_precedence = operator[:precedence]
        next_precedence += 1 if operator[:associativity] == OPERATOR_LEFT

        expr1 = parse_expression(next_precedence)

        # @type [Node::Expression::Base::Binary]
        expr = operator[:class].new(expr, expr1, token.lineno)
        expr.attributes[:operator] = "binary_#{token.value}"

        token = parser.current_token
      end

      return parse_ternary_expression(expr) if precedence.zero?

      expr
    end

    # @return [Node::Expression::Base]
    def parse_primary_expression
      token = parser.current_token

      case token.type
      when Token::NAME_TYPE
        parser.stream.next

        case token.value
        when 'true', 'TRUE'
          node = Node::Expression::Constant.new(true, token.lineno)
        when 'false', 'FALSE'
          node = Node::Expression::Constant.new(false, token.lineno)
        when 'null', 'NULL'
          node = Node::Expression::Constant.new(nil, token.lineno)
        else
          # @todo lots missing here
          # @todo should be a context variable
          node = Node::Expression::Name.new(token.value, token.lineno)
        end
      when Token::NUMBER_TYPE
        parser.stream.next

        node = Node::Expression::Constant.new(token.value, token.lineno)
      when Token::STRING_TYPE, Token::INTERPOLATION_START_TYPE
        node = parse_string_expression
      when Token::PUNCTUATION_TYPE
        case token.value
        when '['
          node = parse_sequence_expression
        when '{'
          node = parse_mapping_expression
        else
          Error::Syntax.new(
            "Unexpected token #{token.type} of value #{token.value}",
            token.lineno,
            parser.stream.source
          )
        end
      else
        raise Error::Syntax.new(
          "Unexpected token '#{token.type}' of value '#{token.value}'",
          token.lineno,
          parser.stream.source
        )
      end

      parse_post_fix_expression(node)
    end

    # @param [Node::Expression::Base] node
    # @return [Node::Expression::Base]
    def parse_post_fix_expression(node)
      loop do
        token = parser.current_token

        unless token.type == Token::PUNCTUATION_TYPE
          break
        end

        case token.value
        when '.', '['
          node = parse_subscript_expression(node)
        when '|'
          node = parse_filter_expression(node)
        else
          break
        end
      end

      node
    end

    def parse_subscript_expression(node)
      if parser.stream.next.value == "."
        return parse_subscript_expression_dot(node)
      end

      parse_subscript_expression_array(node)
    end

    def parse_subscript_expression_dot(node)
      stream = parser.stream
      token = stream.current
      lineno = token.lineno
      arguments = Node::Expression::Array.new({}, lineno)
      token = stream.next

      if token.type == Token::NAME_TYPE
        attribute = Node::Expression::Constant.new(token.value, token.lineno)
      end

      Node::Expression::GetAttribute.new(node, attribute, arguments, nil, token.lineno)
    end

    def parse_sequence_expression
      stream = parser.stream
      stream.expect(Token::PUNCTUATION_TYPE, '[', 'A sequence element was expected')

      node = Node::Expression::Array.new({}, stream.current.lineno)
      first = true

      #raise stream.debug

      until stream.test(Token::PUNCTUATION_TYPE, ']')
        unless first
          stream.expect(Token::PUNCTUATION_TYPE, ',', 'A sequence element must be followed by a comma')

          # trailing comma
          break if stream.test(Token::PUNCTUATION_TYPE, ']')
        end

        first = false

        if stream.next_if(Token::SPREAD_TYPE)
          expr = parse_expression
          expr.attributes[:spread] = true
          node.add_element(expr)
        else
          node.add_element(parse_expression)
        end
      end

      stream.expect(Token::PUNCTUATION_TYPE, ']', 'An opened sequence is not properly closed')

      node
    end

    def parse_mapping_expression
      stream = parser.stream
      stream.expect(Token::PUNCTUATION_TYPE, '{', 'A mapping element was expected')

      node = Node::Expression::Array.new({}, stream.current.lineno)
      first = true

      until stream.test(Token::PUNCTUATION_TYPE, '}')
        unless first
          stream.expect(Token::PUNCTUATION_TYPE, ',', 'A mapping value must be followed by a comma')

          # trailing comma
          if stream.test(Token::PUNCTUATION_TYPE, '}')
            break
          end
        end

        first = false

        if stream.next_if(Token::SPREAD_TYPE)
          value = parse_expression
          value.attributes[:spread] = true
          node.add_element(value)

          next
        end

        # a mapping key can be:
        #
        #  * a number -- 12
        #  * a string -- 'a'
        #  * a name, which is equivalent to a string -- a
        #  * an expression, which must be enclosed in parentheses -- (1 + 2)
        if (token = stream.next_if(Token::NAME_TYPE))
          key = Node::Expression::Constant.new(token.value, token.lineno)

          # {a} is a shortcut for {a: a}
          if stream.test(Token::PUNCTUATION_TYPE, %w[, }])
            value = Node::Expression::Variable::Context.new(key.attributes[:value], key.lineno)
            node.add_element(value, key)

            next
          end
        elsif (token = stream.next_if(Token::STRING_TYPE)) || (token = stream.next_if(Token::NUMBER_TYPE))
          key = Node::Expression::Constant.new(token.value, token.lineno)
        elsif stream.test(Token::PUNCTUATION_TYPE, '(')
          key = parse_expression
        else
          current = stream.current

          raise Error::Syntax.new(
            'A mapping key must be a quoted string, number, name, or expression in parentheses ' +
              "expected token '#{current.type}' of value '#{current.value}'",
            current.lineno,
            stream.source,
          )
        end

        stream.expect(Token::PUNCTUATION_TYPE, ':', 'A mapping key must be followed by a colon (:)')
        value = parse_expression

        node.add_element(value, key)
      end

      stream.expect(Token::PUNCTUATION_TYPE, '}', 'An opened mapping is not properly closed')

      node
    end

    private

    # @return [Parser]
    def parser
      @parser
    end

    # @return [Node::Expression::Base]
    def get_primary
      token = parser.current_token
      unary = false

      if unary
        # @todo unary operators
      elsif token.test(Token::PUNCTUATION_TYPE, '(')
        parser.stream.next
        expr = parse_expression.set_explicit_parentheses

        parser.stream.expect(Token::PUNCTUATION_TYPE, ')', 'Open parenthesis not closed')

        return parse_post_fix_expression(expr)
      end

      parse_primary_expression
    end

    # @param [Node::Expression] expr
    # @return [Node::Expression]
    def parse_ternary_expression(expr)
      while parser.stream.next_if(Token::PUNCTUATION_TYPE, '?')
        expr2 = parse_expression
        expr3 = if parser.stream.next_if(Token::PUNCTUATION_TYPE, ':')
                  parse_expression
                else
                  Node::Expression::Constant.new('', parser.current_token.lineno)
                end

        expr = Node::Expression::Ternary.new(expr, expr2, expr3, parser.current_token.lineno)
      end

      expr
    end

    def parse_filter_expression(node)
      parser.stream.next

      parse_filter_expression_raw(node)
    end

    def parse_filter_expression_raw(node)
      loop do
        token = parser.stream.expect(Token::NAME_TYPE)

        unless parser.stream.test(Token::PUNCTUATION_TYPE, '(')
          arguments = Node::Empty.new
        else
          arguments = parse_only_arguments
        end

        filter = environment.filter(token.value) or raise "TwigFilter #{token.value} not found"
        node = filter.node_class.new(node, filter, arguments, token.lineno)

        unless parser.stream.test(Token::PUNCTUATION_TYPE, '|')
          break
        end

        parser.stream.next
      end

      node
    end

    def parse_string_expression
      stream = parser.stream
      nodes = []

      # a string cannot be followed by another string in a single expression
      next_can_be_string = true

      loop do
        if next_can_be_string && (token = stream.next_if(Token::STRING_TYPE))
          nodes << Node::Expression::Constant.new(token.value, token.lineno)
          next_can_be_string = false
        elsif stream.next_if(Token::INTERPOLATION_START_TYPE)
          nodes << parse_expression
          stream.expect(Token::INTERPOLATION_END_TYPE)
          next_can_be_string = true
        else
          break
        end
      end

      expr = nodes.shift
      nodes.each do |node|
        expr = Node::Expression::Binary::ConcatBinary(expr, node, node.lineno)
      end

      expr
    end

    # @return [Hash]
    def unary_operators
      @unary_operators ||= environment.operators[0]
    end

    # @param [Token] token
    def unary?(token)
      token.test(Token::OPERATOR_TYPE) && unary_operators.key?(token.value)
    end

    # @return [Hash]
    def binary_operators
      @binary_operators ||= environment.operators[1]
    end

    # @param [Token] token
    def binary?(token)
      token.test(Token::OPERATOR_TYPE) && binary_operators.key?(token.value.to_sym)
    end
  end
end
