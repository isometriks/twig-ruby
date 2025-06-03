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
                       token = stream.next
                       Node::Expression::Variable::Context.new(token.value, token.lineno)
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
      end
    end
  end
end
