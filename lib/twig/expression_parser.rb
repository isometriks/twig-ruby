module Twig
  class ExpressionParser
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

      if token.type == Token::OPERATOR_TYPE
        parser.stream.next

        expr1 = parse_expression

        expr = Node::Expression::Binary::AddBinary.new(expr, expr1, token.lineno)
      end

      expr
    end

    def parse_primary_expression
      # $token = $this->parser->getCurrentToken();
      #         switch ($token->getType()) {
      token = parser.current_token

      case token.type
      when Token::NAME_TYPE
        parser.stream.next

        case token.value
        when 'true', 'TRUE'
          node = Node::Expression::ConstantExpression.new(true, token.lineno)
        when 'false', 'FALSE'
          node = Node::Expression::ConstantExpression.new(false, token.lineno)
        else
          # @todo lots missing here
          # @todo should be a context variable
          node = Node::Expression::ConstantExpression.new(token.value, token.lineno)
        end
      when Token::NUMBER_TYPE
        parser.stream.next

        node = Node::Expression::ConstantExpression.new(token.value, token.lineno)
      end

      parse_post_fix_expression node
    end

    def parse_post_fix_expression(node)
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

        parser.stream.expect(Token::PUNCTUATION_TYPE, '(', 'Open parenthesis not closed')

        return parse_post_fix_expression(expr)
      end

      parse_primary_expression
    end
  end
end
