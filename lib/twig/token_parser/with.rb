# frozen_string_literal: true

module Twig
  module TokenParser
    class With < TokenParser::Base
      def parse(token)
        stream = parser.stream

        variables = nil
        only = false

        unless stream.test(Token::BLOCK_END_TYPE)
          variables = parser.expression_parser.parse_expression
          only = !!stream.next_if(Token::NAME_TYPE, 'only')
        end

        stream.expect(Token::BLOCK_END_TYPE)
        body = parser.subparse(decide_with_end, drop_needle: true)
        stream.expect(Token::BLOCK_END_TYPE)

        raise [variables].inspect
      end

      def tag
        'with'
      end

      private

      def decide_with_end
        -> (token) { token.test('endwith') }
      end
    end
=begin
final class WithTokenParser extends AbstractTokenParser
{
    public function parse(Token $token): Node
    {


        $stream->expect(Token::BLOCK_END_TYPE);

        $body = $this->parser->subparse([$this, 'decideWithEnd'], true);

        $stream->expect(Token::BLOCK_END_TYPE);

        return new WithNode($body, $variables, $only, $token->getLine());
    }

    public function decideWithEnd(Token $token): bool
    {
        return $token->test('endwith');
    }

    public function getTag(): string
    {
        return 'with';
    }
=end
  end
end
