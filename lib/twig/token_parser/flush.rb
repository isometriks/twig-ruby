# frozen_string_literal: true

module Twig
  module TokenParser
    # The flush tag, as in Twig: {% flush %}
    class Flush < TokenParser::Base
      def parse(token)
        parser.stream.expect(Token::BLOCK_END_TYPE)

        Node::Flush.new(token.lineno)
      end

      def tag
        'flush'
      end
    end
  end
end
