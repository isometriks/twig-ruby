# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Prefix
      class Literal < PrefixExpressionParser
        def parse(parser, token)
          case token.type
          when Token::SYMBOL_TYPE
            parser.stream.next
            @type = :constant

            return Node::Expression::Constant.new(token.value.to_sym, token.lineno)
          when Token::CLASS_VAR_TYPE
            parser.stream.next
            @type = :variable

            return Node::Expression::Variable::Context.new(token.value, token.lineno)
          when Token::NAME_TYPE
            parser.stream.next

            # We can adjust for a ternary with no space here like a? b : c, we should however ignore function
            # nodes because a?() is fine
            token_value = token.value
            if token.value.end_with?('?') && parser.current_token.value != '('
              parser.stream.inject([Token.new(Token::OPERATOR_TYPE, '?', token.lineno)])
              token_value = token.value.chomp('?')
            end

            case token_value
            when 'true', 'TRUE'
              @type = :constant

              return Node::Expression::Constant.new(true, token.lineno)
            when 'false', 'FALSE'
              @type = :constant

              return Node::Expression::Constant.new(false, token.lineno)
            when 'null', 'NULL', 'nil', 'none', 'NONE'
              @type = :constant

              return Node::Expression::Constant.new(nil, token.lineno)
            else
              @type = :variable

              return Node::Expression::Variable::Context.new(token_value, token.lineno)
            end
          when Token::NUMBER_TYPE
            parser.stream.next
            @type = :constant

            return Node::Expression::Constant.new(token.value, token.lineno)
          when Token::STRING_TYPE, Token::INTERPOLATION_START_TYPE
            @type = :string

            return parse_string_expression(parser)
          when Token::PUNCTUATION_TYPE
            if token.value == '{'
              return parse_mapping_expression(parser)
            else
              raise Error::Syntax.new(
                "Unexpected token \"#{token.to_english}\" of value \"#{token.value}\".",
                token.lineno,
                parser.stream.source
              )
            end
          when Token::OPERATOR_TYPE
            if token.value == '['
              return parse_sequence_expression(parser)
            end

            if (match = token.value.match(Lexer::REGEX_NAME)) && match.to_s == token.value
              # in this context, string operators are variable names
              parser.stream.next
              @type = :variable

              return Node::Expression::Variable::Context.new(token.value, token.lineno)
            end

          end

          raise Error::Syntax.new(
            "Unexpected token \"#{token.type}\" of value \"#{token.value}\".",
            token.lineno,
            parser.stream.source
          )
        end

        def name
          @type || :literal
        end

        def precedence
          0
        end

        private

        # @param [Parser]
        def parse_string_expression(parser)
          stream = parser.stream
          nodes = []

          # a string cannot be followed by another string in a single expression
          next_can_be_string = true

          loop do
            if next_can_be_string && (token = stream.next_if(Token::STRING_TYPE))
              nodes << Node::Expression::Constant.new(token.value, token.lineno)
              next_can_be_string = false
            elsif stream.next_if(Token::INTERPOLATION_START_TYPE)
              nodes << parser.parse_expression
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

        # @param [Parser] parser
        def parse_sequence_expression(parser)
          @type = :sequence

          stream = parser.stream
          stream.expect(Token::OPERATOR_TYPE, '[', 'A sequence element was expected')

          node = Node::Expression::Array.new(AutoHash.new, stream.current.lineno)
          first = true

          # raise stream.debug

          until stream.test(Token::PUNCTUATION_TYPE, ']')
            unless first
              stream.expect(Token::PUNCTUATION_TYPE, ',', 'A sequence element must be followed by a comma')

              # trailing comma
              break if stream.test(Token::PUNCTUATION_TYPE, ']')
            end

            first = false

            if stream.test(Token::PUNCTUATION_TYPE, ',') || stream.test(Token::PUNCTUATION_TYPE, ']')
              node.add_element(Node::Expression::EmptySlot.new(stream.current.lineno))
            elsif stream.next_if(Token::OPERATOR_TYPE, '...')
              expr = parser.parse_expression
              node.add_element(Node::Expression::Unary::ArraySpread.new(expr, expr.lineno))
            else
              node.add_element(parser.parse_expression)
            end
          end

          stream.expect(Token::PUNCTUATION_TYPE, ']', 'An opened sequence is not properly closed')

          node
        end

        # @param [Parser] parser
        def parse_mapping_expression(parser)
          @type = :mapping

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

            if stream.next_if(Token::OPERATOR_TYPE, '...')
              value = parser.parse_expression
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
            elsif stream.test(Token::OPERATOR_TYPE, '(')
              key = parser.parse_expression
            else
              current = stream.current

              raise Error::Syntax.new(
                'A mapping key must be a quoted string, number, name, or expression in parentheses ' \
                "expected token '#{current.type}' of value '#{current.value}'.",
                current.lineno,
                stream.source
              )
            end

            stream.expect(Token::PUNCTUATION_TYPE, ':', 'A mapping key must be followed by a colon (:)')
            value = parser.parse_expression

            node.add_element(value, key)
          end

          stream.expect(Token::PUNCTUATION_TYPE, '}', 'An opened mapping is not properly closed')

          node
        end
      end
    end
  end
end
