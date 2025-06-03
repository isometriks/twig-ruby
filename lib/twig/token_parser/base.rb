# frozen_string_literal: true

module Twig
  module TokenParser
    class Base
      # @return [Parser]
      attr_accessor :parser

      # @param [Token] token
      def parse(token)
        raise 'parse is not implemented'
      end

      # @return [String]
      def tag
        raise 'tag is not implemented'
      end

      private

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
    end
  end
end
