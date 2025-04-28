# frozen_string_literal: true

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
      if (arrow = parse_arrow)
        return arrow
      end

      expr = primary
      token = parser.current_token

      while binary?(token) && binary_operators[token.value.to_sym][:precedence] >= precedence
        operator = binary_operators[token.value.to_sym]
        parser.stream.next

        # @type [Node::Expression::Binary::Base]
        expr = if token.value == 'is not'
                 parse_not_test_expression(expr)
               elsif token.value == 'is'
                 parse_test_expression(expr)
               elsif operator.key?(:callable)
                 operator[:callable].call(parser, expr)
               else
                 next_precedence = operator[:precedence]
                 next_precedence += 1 if operator[:associativity] == OPERATOR_LEFT

                 expr1 = parse_expression(next_precedence)

                 operator[:class].new(expr, expr1, token.lineno)
               end

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
      when Token::SYMBOL_TYPE
        parser.stream.next

        node = Node::Expression::Constant.new(token.value.to_sym, token.lineno)
      when Token::CLASS_VAR_TYPE
        parser.stream.next

        node = Node::Expression::Variable::Context.new(token.value, token.lineno)
      when Token::NAME_TYPE
        parser.stream.next

        node = case token.value
               when 'true', 'TRUE'
                 Node::Expression::Constant.new(true, token.lineno)
               when 'false', 'FALSE'
                 Node::Expression::Constant.new(false, token.lineno)
               when 'null', 'NULL', 'nil'
                 Node::Expression::Constant.new(nil, token.lineno)
               else
                 if parser.current_token.value == '('
                   get_function_node(token.value, token.lineno)
                 else
                   Node::Expression::Variable::Context.new(token.value, token.lineno)
                 end
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
          raise Error::Syntax.new(
            "Unexpected token \"#{token.type}\" of value \"#{token.value}\"",
            token.lineno,
            parser.stream.source
          )
        end
      else
        raise Error::Syntax.new(
          "Unexpected token \"#{token.type}\" of value \"#{token.value}\"",
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

    # @param [Node::Expression::Base] node
    # @return [Node::Expression::Base]
    def parse_subscript_expression(node)
      if parser.stream.next.value == '.'
        return parse_subscript_expression_dot(node)
      end

      parse_subscript_expression_array(node)
    end

    # @param [Node::Expression::Base] node
    # @return [Node::Expression::Base]
    def parse_subscript_expression_dot(node)
      stream = parser.stream
      token = stream.current
      lineno = token.lineno
      arguments = Node::Expression::Array.new({}, lineno)
      type = Template::ANY_CALL

      if stream.next_if(Token::PUNCTUATION_TYPE, '(')
        attribute = parse_expression
        stream.expect(Token::PUNCTUATION_TYPE, ')')
      else
        token = stream.next

        if [Token::NAME_TYPE, Token::NUMBER_TYPE].include?(token.type) ||
           (token.type == Token::OPERATOR_TYPE && token.value.match(/\A#{Lexer::REGEX_NAME}/))
          attribute = Node::Expression::Constant.new(token.value, token.lineno)
        else
          raise Error::Syntax.new(
            "Expected name or number, got #{token.value} of type #{token.type}",
            token.lineno,
            stream.source
          )
        end
      end

      if stream.test(Token::PUNCTUATION_TYPE, '(')
        type = Template::METHOD_CALL
        arguments = create_arguments(token.lineno)
      end

      if node.is_a?(Node::Expression::Name) && (
          parser.imported_symbol(:template, node.attributes[:name]) ||
            (node.attributes[:name] == '_self' && attribute.is_a?(Node::Expression::Constant))
        )
        return Node::Expression::MacroReference.new(
          Node::Expression::Variable::Template.new(node.attributes[:name], node.lineno),
          "macro_#{attribute.attributes[:value]}",
          arguments,
          node.lineno
        )
      end

      Node::Expression::GetAttribute.new(node, attribute, arguments, type, token.lineno)
    end

    # @return [Node::Expression::Base]
    def parse_sequence_expression
      stream = parser.stream
      stream.expect(Token::PUNCTUATION_TYPE, '[', 'A sequence element was expected')

      node = Node::Expression::Array.new({}, stream.current.lineno)
      first = true

      # raise stream.debug

      until stream.test(Token::PUNCTUATION_TYPE, ']')
        unless first
          stream.expect(Token::PUNCTUATION_TYPE, ',', 'A sequence element must be followed by a comma')

          # trailing comma
          break if stream.test(Token::PUNCTUATION_TYPE, ']')
        end

        first = false

        if stream.next_if(Token::SPREAD_TYPE)
          expr = parse_expression
          node.add_element(Node::Expression::Unary::ArraySpread.new(expr, expr.lineno))
        else
          node.add_element(parse_expression)
        end
      end

      stream.expect(Token::PUNCTUATION_TYPE, ']', 'An opened sequence is not properly closed')

      node
    end

    # @return [Node::Expression::Base]
    def parse_mapping_expression
      stream = parser.stream
      stream.expect(Token::PUNCTUATION_TYPE, '{', 'A mapping element was expected')

      node = Node::Expression::Hash.new({}, stream.current.lineno)
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
          node.add_element(Node::Expression::Unary::HashSpread.new(value, value.lineno))

          next
        end

        # a mapping key can be:
        #
        #  * a number -- 12
        #  * a string -- 'a'
        #  * a name, which is equivalent to a symbol -- a
        #  * an expression, which must be enclosed in parentheses -- (1 + 2)
        if (token = stream.next_if(Token::NAME_TYPE))
          key = Node::Expression::Constant.new(token.value.to_sym, token.lineno)

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
            'A mapping key must be a quoted string, number, name, or expression in parentheses ' \
            "expected token '#{current.type}' of value '#{current.value}'",
            current.lineno,
            stream.source
          )
        end

        stream.expect(Token::PUNCTUATION_TYPE, ':', 'A mapping key must be followed by a colon (:)')
        value = parse_expression

        node.add_element(value, key)
      end

      stream.expect(Token::PUNCTUATION_TYPE, '}', 'An opened mapping is not properly closed')

      node
    end

    def get_function_node(name, line)
      # @todo lots of stuff in this method

      if (aliased = parser.imported_symbol(:function, name))
        return Node::Expression::MacroReference.new(
          aliased[:node].nodes[:var],
          aliased[:name],
          create_arguments(line),
          line
        )
      end

      args = parse_named_arguments

      if (function = environment.function(name))
        if (callable = function.parser_callable)
          fake_node = Node::Empty.new(line)
          fake_node.source_context = parser.stream.source

          callable.call(parser, fake_node, args, line)
        else
          Node::Expression::Function.new(function, args, line)
        end
      elsif parser.ignore_unknown_twig_callables?
        function = TwigFunction.new(name, -> {})
        Node::Expression::Function.new(function, Node::Nodes.new({}), line)
      elsif environment.allow_helper_methods?
        Node::Expression::HelperMethod.new(name, args, line)
      else
        raise Error::Syntax.new("Unknown \"#{name}\" function", line, parser.stream.source)
      end
    end

    def parse_named_arguments
      args = AutoHash.new
      stream = parser.stream
      stream.expect(Token::PUNCTUATION_TYPE, '(', 'A list of arguments must begin with an opening parenthesis')
      has_spread = false

      until stream.test(Token::PUNCTUATION_TYPE, ')')
        unless args.empty?
          stream.expect(Token::PUNCTUATION_TYPE, ',', 'Arguments must be separated by a comma')

          # if above was trailing comma, exit early
          break if stream.test(Token::PUNCTUATION_TYPE, ')')
        end

        if stream.next_if(Token::SPREAD_TYPE)
          has_spread = true
          value = Node::Expression::Unary::Spread.new(parse_expression, stream.current.lineno)
        elsif has_spread
          raise Error::Syntax.new(
            'Normal arguments must be placed before argument unpacking.',
            stream.current.lineno,
            stream.source
          )
        else
          value = parse_expression
        end

        name = nil
        if (token = stream.next_if(Token::OPERATOR_TYPE, '=')) ||
           (token = stream.next_if(Token::PUNCTUATION_TYPE, ':'))
          # Allow quoted kwargs - form_with("data-turbo-stream": true)
          if value.is_a?(Node::Expression::Constant) && value.attributes[:value].is_a?(String)
            name = value.attributes[:value]
          elsif value.is_a?(Node::Expression::Name)
            name = value.attributes[:name]
          else
            raise Error::Syntax.new(
              "A parameter name must be a string, #{value.class.name} given.",
              token.lineno,
              stream.source
            )
          end

          value = parse_expression
        end

        if name.nil?
          args.add(value)
        else
          args[name] = value
        end
      end

      stream.expect(Token::PUNCTUATION_TYPE, ')', 'A list of arguments must be closed by a parenthesis')

      Node::Nodes.new(args)
    end

    # @return [Parser]
    attr_reader :parser

    # @return [Node::Expression::Base]
    def primary
      token = parser.current_token

      if unary?(token)
        operator = unary_operators[token.value.to_sym]
        parser.stream.next

        expr = parse_expression(operator[:precedence])
        expr = operator[:class].new(expr, token.lineno)
        expr.attributes[:operator] = "unary_#{token.value}"

        return parse_post_fix_expression(expr)
      elsif token.test(Token::PUNCTUATION_TYPE, '(')
        parser.stream.next
        expr = parse_expression.set_explicit_parentheses

        parser.stream.expect(Token::PUNCTUATION_TYPE, ')', 'Open parenthesis not closed')

        return parse_post_fix_expression(expr)
      end

      parse_primary_expression
    end

    # @param [Node::Expression::Base] expr
    # @return [Node::Expression::Base]
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

    # @return [Node::Expression::Base]
    def parse_filter_expression(node)
      parser.stream.next

      parse_filter_expression_raw(node)
    end

    # @param [Node::Expression::Base] node
    # @return [Node::Expression::Base]
    def parse_filter_expression_raw(node)
      loop do
        token = parser.stream.expect(Token::NAME_TYPE)

        arguments = if parser.stream.test(Token::PUNCTUATION_TYPE, '(')
                      parse_named_arguments
                    else
                      Node::Empty.new
                    end

        filter = get_filter(token.value, token.lineno)
        node = filter.node_class.new(node, filter, arguments, token.lineno)

        unless parser.stream.test(Token::PUNCTUATION_TYPE, '|')
          break
        end

        parser.stream.next
      end

      node
    end

    # @return [Node::Nodes]
    def parse_assignment_expression
      stream = parser.stream
      targets = AutoHash.new

      loop do
        token = parser.current_token

        if stream.test(Token::OPERATOR_TYPE) && token.value.match(Lexer::REGEX_NAME)
          # in this context, string operators are variables names
          parser.stream.next
        else
          stream.expect(Token::NAME_TYPE, nil, 'Only variables can be assigned to')
        end

        targets << Node::Expression::Variable::AssignContext.new(token.value, token.lineno)

        unless stream.next_if(Token::PUNCTUATION_TYPE, ',')
          break
        end
      end

      Node::Nodes.new(targets)
    end

    # @return [Node::Nodes]
    def parse_multi_target_expression
      targets = AutoHash.new

      loop do
        targets << parse_expression

        unless parser.stream.next_if(Token::PUNCTUATION_TYPE, ',')
          break
        end
      end

      Node::Nodes.new(targets)
    end

    # @param [Node::Base] node
    def parse_not_test_expression(node)
      Node::Expression::Unary::Not.new(parse_test_expression(node), parser.current_token.lineno)
    end

    # @param [Node::Base] node
    # @return [Node::Expression::Test::Base]
    def parse_test_expression(node)
      stream = parser.stream
      test = get_test(node.lineno)

      arguments = nil
      if stream.test(Token::PUNCTUATION_TYPE, '(')
        arguments = parse_named_arguments
      elsif test.one_mandatory_argument?
        arguments = Node::Nodes.new(AutoHash.new.add(primary))
      end

      # @todo Defined macro expresion

      test.node_class.new(node, test, arguments, parser.current_token.lineno)
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
        expr = Node::Expression::Binary::Concat.new(expr, node, node.lineno)
      end

      expr
    end

    # @param [Node::Base]
    # @return [Node::Expression::Base]
    def parse_subscript_expression_array(node)
      stream = parser.stream
      token = stream.current
      lineno = token.lineno
      arguments = Node::Expression::Array.new({}, lineno)

      slice = false
      if stream.test(Token::PUNCTUATION_TYPE, ':')
        slice = true
        attribute = Node::Expression::Constant.new(0, token.lineno)
      else
        attribute = parse_expression
      end

      if stream.next_if(Token::PUNCTUATION_TYPE, ':')
        slice = true
      end

      if slice
        length = if stream.test(Token::PUNCTUATION_TYPE, ']')
                   Node::Expression::Constant.new(nil, token.lineno)
                 else
                   parse_expression
                 end

        filter = get_filter('slice', token.lineno)
        arguments = Node::Nodes.new(AutoHash.new.add(attribute, length))
        filter = filter.node_class.new(node, filter, arguments, token.lineno)

        stream.expect(Token::PUNCTUATION_TYPE, ']')

        return filter
      end

      stream.expect(Token::PUNCTUATION_TYPE, ']')

      Node::Expression::GetAttribute.new(node, attribute, arguments, Template::ARRAY_CALL, lineno)
    end

    # @return [Hash]
    def unary_operators
      @unary_operators ||= environment.operators[0]
    end

    # @return [Hash]
    def binary_operators
      @binary_operators ||= environment.operators[1]
    end

    # @param [Token] token
    def unary?(token)
      token.test(Token::OPERATOR_TYPE) && unary_operators.key?(token.value.to_sym)
    end

    # @param [Token] token
    def binary?(token)
      token.test(Token::OPERATOR_TYPE) && binary_operators.key?(token.value.to_sym)
    end

    # @return [Filter]
    def get_filter(name, lineno)
      unless (filter = environment.filter(name))
        unless parser.ignore_unknown_twig_callables?
          raise Error::Syntax.new("Unknown '#{name}' filter", lineno, parser.stream.source)
        end

        filter = TwigFilter.new(name, -> {})
      end

      filter
    end

    private

    def parse_arrow
      stream = parser.stream

      # short array syntax (one argument, no parentheses)?
      if stream.look(1).test(Token::ARROW_TYPE)
        line = stream.current.lineno
        token = stream.expect(Token::NAME_TYPE)
        names = AutoHash.new.add(Node::Expression::Variable::AssignContext.new(token.value, token.lineno))
        stream.expect(Token::ARROW_TYPE)

        return Node::Expression::ArrowFunction.new(parse_expression, Node::Nodes.new(names), line)
      end

      # first, determine if we are parsing an arrow function by finding => (long form)
      i = 0

      unless stream.look(i).test(Token::PUNCTUATION_TYPE, '(')
        return nil
      end

      i += 1

      loop do
        # variable name
        i += 1
        unless stream.look(i).test(Token::PUNCTUATION_TYPE, ',')
          break
        end

        i += 1
      end

      unless stream.look(i).test(Token::PUNCTUATION_TYPE, ')')
        return nil
      end

      i += 1

      unless stream.look(i).test(Token::ARROW_TYPE)
        return nil
      end

      # yes, let's parse it properly
      token = stream.expect(Token::PUNCTUATION_TYPE, '(')
      line = token.lineno
      names = AutoHash.new

      loop do
        token = stream.expect(Token::NAME_TYPE)
        names << Node::Expression::Variable::AssignContext.new(token.value, token.lineno)

        unless stream.next_if(Token::PUNCTUATION_TYPE, ',')
          break
        end
      end

      stream.expect(Token::PUNCTUATION_TYPE, ')')
      stream.expect(Token::ARROW_TYPE)

      Node::Expression::ArrowFunction.new(parse_expression, Node::Nodes.new(names), line)
    end

    # @return [TwigTest]
    def get_test(line)
      stream = parser.stream
      name = stream.expect(Token::NAME_TYPE).value

      if stream.test(Token::NAME_TYPE)
        # try 2 word tests
        name = "#{name} #{parser.current_token.value}"

        if (test = environment.test(name))
          stream.next
        end
      else
        test = environment.test(name)
      end

      if test.nil? && parser.ignore_unknown_twig_callables?
        test = TwigTest.new(name, -> {})
      end

      unless test
        raise Error::Syntax.new("Unknown #{name} test.", line, stream.source)
      end

      test
    end

    # @param [Integer] lineno
    def create_arguments(lineno)
      arguments = Node::Expression::Hash.new({}, lineno)

      parse_named_arguments.nodes.each do |key, node|
        arguments.add_element(node, Node::Expression::Variable::Local.new(key, lineno))
      end

      arguments
    end
  end
end
