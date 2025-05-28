# frozen_string_literal: true

module Twig
  module TokenParser
    # Defines a variable.
    #
    #  {% set foo = 'foo' %}
    #  {% set foo = [1, 2] %}
    #  {% set foo = {'foo': 'bar'} %}
    #  {% set foo = 'foo' ~ 'bar' %}
    #  {% set foo, bar = 'foo', 'bar' %}
    #  {% set foo %}Some content{% endset %}
    class Set < Base
      def parse(token)
        lineno = token.lineno
        stream = parser.stream
        names = parser.expression_parser.parse_assignment_expression
        capture = false

        if stream.next_if(Token::OPERATOR_TYPE, '=')
          values = parser.expression_parser.parse_multi_target_expression

          stream.expect(Token::BLOCK_END_TYPE)

          if names.length != values.length
            raise Error::Syntax.new(
              'When using set, you must have the same number of variables and assignments',
              stream.current.lineno,
              stream.source
            )
          end
        else
          capture = true

          if names.length > 1
            raise Error::Syntax.new(
              'When using set with a block, you cannot have a multi-target',
              stream.current.lineno,
              stream.source
            )
          end

          stream.expect(Token::BLOCK_END_TYPE)
          values = parser.subparse(method(:decide_block_end), drop_needle: true)
          stream.expect(Token::BLOCK_END_TYPE)
        end

        Node::Set.new(capture, names, values, lineno)
      end

      def tag
        'set'
      end

      private

      def decide_block_end(token)
        token.test('endset')
      end
    end
  end
end
