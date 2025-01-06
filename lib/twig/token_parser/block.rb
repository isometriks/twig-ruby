module Twig
  module TokenParser
    # Marks a section of a template as being reusable.
    #
    #  {% block head %}
    #    <link rel="stylesheet" href="style.css" />
    #    <title>{% block title %}{% endblock %} - My Webpage</title>
    #  {% endblock %}
    class Block < Base
      def parse(token)
        lineno = token.lineno
        stream = parser.stream
        name = stream.expect(Token::NAME_TYPE).value
        block = Node::Block.new(name, Node::EmptyNode.new, lineno)

        parser.set_block(name, block)
        parser.push_local_scope
        parser.push_block_stack(name)

        if stream.next_if(Token::BLOCK_END_TYPE)
          body = parser.subparse(decide_block_end, drop_needle: true)

          if (token = stream.next_if(Token::NAME_TYPE))
            raise "Expected end block for #{name}, given #{token.value}" unless token.value == name
          end
        else
          body = Node::Nodes.new({
            0 => Nodes::PrintNode.new(parser.expression_parser.parse_expression, lineno),
          })
        end

        stream.expect(Token::BLOCK_END_TYPE)
        block.nodes[:body] = body

        parser.pop_block_stack
        parser.pop_local_scope

        Node::BlockReference.new(name, lineno)
      end

      def tag
        'block'
      end

      private

      def decide_block_end
        -> (token) { token.test('endblock') }
      end
    end
  end
end
