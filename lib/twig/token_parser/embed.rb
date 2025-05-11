# frozen_string_literal: true

require_relative 'include'

module Twig
  module TokenParser
    class Embed < Include
      def parse(token)
        stream = parser.stream
        parent = parser.expression_parser.parse_expression

        variables, only, ignore_missing = parse_arguments

        parent_token = fake_parent_token = Token.new(Token::STRING_TYPE, '__parent__', token.lineno)

        if parent.is_a?(Node::Expression::Constant)
          parent_token = Token.new(Token::STRING_TYPE, parent.attributes[:value], token.lineno)
        elsif parent.is_a?(Node::Expression::Variable::Context)
          parent_token = Token.new(Token::NAME_TYPE, parent.attributes[:name], token.lineno)
        end

        # inject a fake parent to make the parent() function works
        stream.inject([
          Token.new(Token::BLOCK_START_TYPE, '', token.lineno),
          Token.new(Token::NAME_TYPE, 'extends', token.lineno),
          parent_token,
          Token.new(Token::BLOCK_END_TYPE, '', token.lineno),
        ])

        node = parser.parse(stream, decide_block_end, drop_needle: true)

        # override the parent with the correct one
        if fake_parent_token == parent_token
          node.nodes[:parent] = parent
        end

        parser.embed_template(node)

        stream.expect(Token::BLOCK_END_TYPE)

        Node::Embed.new(
          node.template_name,
          node.attributes[:index],
          variables,
          only,
          ignore_missing,
          token.lineno
        )
      end

      def tag
        'embed'
      end

      private

      def decide_block_end
        ->(token) { token.test('endembed') }
      end
    end
  end
end
