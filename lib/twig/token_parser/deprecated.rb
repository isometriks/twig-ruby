# frozen_string_literal: true

module Twig
  module TokenParser
    class Deprecated < Base
      def parse(token)
        stream = parser.stream
        expr = parser.expression_parser.parse_expression
        node = Node::Deprecated.new(expr, token.lineno)

        while stream.test(Token::NAME_TYPE)
          k = stream.current.value
          stream.next
          stream.expect(Token::OPERATOR_TYPE, '=')

          case k
          when 'package'
            node.nodes[:package] = parser.expression_parser.parse_expression
          when 'version'
            node.nodes[:version] = parser.expression_parser.parse_expression
          else
            raise Error::Syntax.new(
              "Unknown \"#{k}\" option.",
              stream.current.lineno,
              stream.source_context
            )
          end
        end

        stream.expect(Token::BLOCK_END_TYPE)

        node
      end

      def tag
        'deprecated'
      end
    end
  end
end
