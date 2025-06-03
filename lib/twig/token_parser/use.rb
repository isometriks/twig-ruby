# frozen_string_literal: true

module Twig
  module TokenParser
    # Imports blocks defined in another template into the current template.
    #
    # {% extends "base.html" %}
    # {% use "blocks.html" %}
    #
    # {% block title %}{% endblock %}
    class Use < Base
      def parse(token)
        template = parser.parse_expression
        stream = parser.stream

        unless template.is_a?(Node::Expression::Constant)
          raise Error::Syntax.new(
            'The template references in a "use" statement must be a string.',
            stream.current.lineno,
            stream.source
          )
        end

        targets = {}

        if stream.next_if('with')
          loop do
            aliased = name = stream.expect(Token::NAME_TYPE).value

            if stream.next_if('as')
              aliased = stream.expect(Token::NAME_TYPE).value
            end

            targets[name] = Node::Expression::Constant.new(aliased, -1)

            unless stream.next_if(Token::PUNCTUATION_TYPE, ',')
              break
            end
          end
        end

        stream.expect(Token::BLOCK_END_TYPE)

        parser.add_trait(Node::Nodes.new({ template:, targets: Node::Nodes.new(targets) }))

        Node::Empty.new(token.lineno)
      end

      def tag
        'use'
      end
    end
  end
end
