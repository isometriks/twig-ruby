# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class SquareBracket < InfixExpressionParser
        def parse(parser, left, token)
          stream = parser.stream
          lineno = token.lineno
          arguments = Node::Expression::Array.new({}, lineno)

          slice = false
          if stream.test(Token::PUNCTUATION_TYPE, ':')
            slice = true
            attribute = Node::Expression::Constant.new(0, token.lineno)
          else
            attribute = parser.parse_expression
          end

          if stream.next_if(Token::PUNCTUATION_TYPE, ':')
            slice = true
          end

          if slice || stream.test(Token::SYMBOL_TYPE)
            length = if stream.test(Token::PUNCTUATION_TYPE, ']')
                       Node::Expression::Constant.new(nil, token.lineno)
                     elsif stream.test(Token::SYMBOL_TYPE)
                       # The lexer reads x[1:a] as 1 and the symbol :a, but
                       # the : is the slice's and the name a starts the length
                       # expression, as in x[1:a + 1] or x[1:not a]
                       symbol = stream.current
                       type = slice_length_type(parser, symbol)
                       stream.replace_current(Token.new(type, symbol.value, symbol.lineno, symbol.offset&.+(1)))
                       parser.parse_expression
                     else
                       parser.parse_expression
                     end

            filter = parser.filter('slice', token.lineno)
            arguments = Node::Nodes.new(AutoHash.new.add(attribute, length))
            filter = filter.node_class.new(left, filter, arguments, token.lineno)

            stream.expect(Token::PUNCTUATION_TYPE, ']')

            return filter
          end

          stream.expect(Token::PUNCTUATION_TYPE, ']')

          Node::Expression::GetAttribute.new(left, attribute, arguments, Template::ARRAY_CALL, lineno)
        end

        def name
          '['
        end

        def description
          'Array access'
        end

        def precedence
          512
        end

        def associativity
          LEFT
        end

        private

        # The type the lexer gives the word after the slice's : when it reads
        # it on its own: a unary operator, such as not, when a space or a
        # bracket follows it, as Twig's lexer requires, or else a name
        def slice_length_type(parser, symbol)
          code = parser.stream.source&.code
          following = code[symbol.offset + 1 + symbol.value.length] if code && symbol.offset

          if following&.match?(/[[:space:]()\[{]/) &&
             parser.environment.expression_parsers.by_name(:prefix, symbol.value)
            Token::OPERATOR_TYPE
          else
            Token::NAME_TYPE
          end
        end
      end
    end
  end
end
