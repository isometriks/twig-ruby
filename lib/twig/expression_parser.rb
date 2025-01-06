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

    # @return [Node::Expression::Expression]
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

        # @type [Node::Expression::Expression::Binary]
        expr = operator[:class].new(expr, expr1, token.lineno)
        expr.attributes[:operator] = "binary_#{token.value}"

        token = parser.current_token
      end

      expr
    end

    # @return [Node::Expression::Expression]
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
      else
        raise "Unexpected token type: #{token.type}"
      end

      parse_post_fix_expression(node)
    end

    # @param [Node::Expression::Expression] node
    # @return [Node::Expression::Expression]
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

    private

    # @return [Parser]
    def parser
      @parser
    end

    # @return [Node::Expression::Expression]
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

    def parse_filter_expression(node)
      parser.stream.next

      parse_filter_expression_raw(node)
    end

    def parse_filter_expression_raw(node)
      loop do
        token = parser.stream.expect(Token::NAME_TYPE)

        unless parser.stream.test(Token::PUNCTUATION_TYPE, '(')
          arguments = Node::EmptyNode.new
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
