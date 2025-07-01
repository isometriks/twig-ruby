# frozen_string_literal: true

module Twig
  module TokenParser
    class Cache < TokenParser::Base
      include Twig::ExpressionParser::ParsesArguments

      def parse(token)
        stream = parser.stream
        lineno = token.lineno
        arguments = parse_named_arguments(parser)

        stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(method(:decide_cache_end), drop_needle: true)
        stream.expect(Token::BLOCK_END_TYPE)

        Node::Cache.new(arguments, body, lineno)
      end

      def tag
        'cache'
      end

      private

      def decide_cache_end(token)
        token.test('endcache')
      end
    end
  end
end
