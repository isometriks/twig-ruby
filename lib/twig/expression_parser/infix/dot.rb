# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class Dot < InfixExpressionParser
        include ParsesArguments

        def parse(parser, left, _token)
          stream = parser.stream
          token = stream.current
          lineno = token.lineno
          arguments = Node::Expression::Array.new(AutoHash.new, lineno)
          type = Template::ANY_CALL

          if stream.next_if(Token::OPERATOR_TYPE, '(')
            attribute = parser.parse_expression
            stream.expect(Token::PUNCTUATION_TYPE, ')')
          else
            token = stream.next

            if [Token::NAME_TYPE, Token::NUMBER_TYPE].include?(token.type) ||
               (token.type == Token::OPERATOR_TYPE && token.value.match(/\A#{Lexer::REGEX_NAME}/))
              attribute = Node::Expression::Constant.new(token.value, token.lineno)
            else
              raise Error::Syntax.new(
                "Expected name or number, got value \"#{token.value}\" of type \"#{token.to_english}\".",
                token.lineno,
                stream.source
              )
            end
          end

          macro_target = left.is_a?(Node::Expression::Name) && (
            parser.imported_symbol(:template, left.attributes[:name]) || left.attributes[:name] == '_self'
          )

          if stream.test(Token::OPERATOR_TYPE, '(')
            type = Template::METHOD_CALL
            arguments = parse_callable_arguments(parser, token.lineno, preserve_names: macro_target)
          end

          if macro_target
            reference = Node::Expression::MacroReference.new(
              Node::Expression::Variable::Template.new(left.attributes[:name], left.lineno),
              # macros.(name)() calls the macro named by the value of name
              attribute.is_a?(Node::Expression::Constant) ? attribute.attributes[:value].to_s : attribute,
              arguments,
              left.lineno
            )
            reference.call_parentheses = type == Template::METHOD_CALL

            return reference
          end

          Node::Expression::GetAttribute.new(left, attribute, arguments, type, token.lineno)
        end

        def name
          '.'
        end

        def description
          'Get an attribute on a variable'
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
