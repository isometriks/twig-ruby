# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Prefix
      class Grouping < PrefixExpressionParser
        def parse(parser, token)
          stream = parser.stream
          expr = parser.parse_expression(precedence)

          if stream.next_if(Token::PUNCTUATION_TYPE, ')')
            unless stream.test(Token::OPERATOR_TYPE, '=>')
              return expr.set_explicit_parentheses
            end

            return Node::Expression::Array.new(AutoHash.new.add(expr), token.lineno)
          end

          # determine if we are parsing arrow function arguments
          unless stream.test(Token::PUNCTUATION_TYPE, ',')
            stream.expect(Token::PUNCTUATION_TYPE, ')', 'An opened parenthesis is not properly closed.')
          end

          names = AutoHash.new.add(expr)
          loop do
            if stream.next_if(Token::PUNCTUATION_TYPE, ')')
              break
            end

            stream.expect(Token::PUNCTUATION_TYPE, ',')
            token = stream.expect(Token::NAME_TYPE)
            names << Node::Expression::Variable::Context.new(token.value, token.lineno)
          end

          unless stream.test(Token::OPERATOR_TYPE, '=>')
            raise Error::Syntax.new(
              'A list of variables must be followed by an arrow.',
              stream.current.lineno,
              stream.source
            )
          end

          Node::Expression::Array.new(names, token.lineno)
        end

        def name
          '('
        end

        def description
          'Explicit group expression (a)'
        end

        def precedence
          0
        end
      end
    end
  end
end
