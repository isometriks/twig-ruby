# frozen_string_literal: true

module Twig
  module TokenParser
    # {% types { foo: 'string', bar?: 'int' } %}, braces optional
    class Types < TokenParser::Base
      def parse(token)
        stream = parser.stream
        types, nodes = parse_simple_mapping_expression(stream)
        stream.expect(Token::BLOCK_END_TYPE)

        Node::Types.new(types, nodes, token.lineno)
      end

      def tag
        'types'
      end

      private

      # @param [TokenStream] stream
      def parse_simple_mapping_expression(stream)
        enclosed = stream.next_if(Token::PUNCTUATION_TYPE, '{')
        types = {}
        nodes = {}
        first = true

        until stream.test(Token::PUNCTUATION_TYPE, '}') || stream.test(Token::BLOCK_END_TYPE)
          unless first
            stream.expect(Token::PUNCTUATION_TYPE, ',', 'A type string must be followed by a comma')

            # trailing ,?
            break if stream.test(Token::PUNCTUATION_TYPE, '}') || stream.test(Token::BLOCK_END_TYPE)
          end
          first = false

          name_token = stream.expect(Token::NAME_TYPE)
          name = name_token.value

          if stream.next_if(Token::OPERATOR_TYPE, '?:')
            optional = true
          else
            # The lexer reads foo?: as the predicate name foo? followed by a colon
            optional = name.end_with?('?') || !stream.next_if(Token::OPERATOR_TYPE, '?').nil?
            name = name.delete_suffix('?')
            stream.expect(Token::PUNCTUATION_TYPE, ':', 'A type name must be followed by a colon (:)')
          end

          type = stream.expect(Token::STRING_TYPE).value

          types[name] = { type:, optional: }
          nodes[name] = Node::Type.new(name, type, optional, name_token.lineno)
        end

        if enclosed
          stream.expect(Token::PUNCTUATION_TYPE, '}', 'An opened mapping is not properly closed')
        end

        [types, nodes]
      end
    end
  end
end
