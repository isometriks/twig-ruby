# frozen_string_literal: true

module Twig
  module TokenParser
    # Defines a macro.
    #
    # {% macro input(name, value, type, size) %}
    #  <input type="{{ type|default('text') }}" name="{{ name }}" value="{{ value|e }}" size="{{ size|default(20) }}" />
    # {% endmacro %}
    #
    class Macro < Base
      def parse(token)
        lineno = token.lineno
        stream = parser.stream
        name = stream.expect(Token::NAME_TYPE).value
        arguments = parse_definition

        stream.expect(Token::BLOCK_END_TYPE)
        parser.push_local_scope
        body = parser.subparse(decide_block_end, drop_needle: true)

        if (token = stream.next_if(Token::NAME_TYPE))
          value = token.value

          if value != name
            raise Error::Syntax.new(
              "Expected endmacro for macro \"#{name}\" (but \"#{value}\" given).",
              stream.current.lineno,
              stream.source_context
            )
          end
        end

        parser.pop_local_scope
        stream.expect(Token::BLOCK_END_TYPE)

        parser.set_macro(name, Node::Macro.new(name, Node::Body.new({ 0 => body }), arguments, lineno))

        Node::Empty.new(lineno)
      end

      def decide_block_end
        ->(token) { token.test('endmacro') }
      end

      def tag
        'macro'
      end

      private

      def parse_definition
        arguments = Node::Expression::Hash.new({}, parser.current_token.lineno)
        stream = parser.stream
        stream.expect(Token::PUNCTUATION_TYPE, '(', 'A list of arguments must begin with an opening parenthesis')

        until stream.test(Token::PUNCTUATION_TYPE, ')')
          unless arguments.empty?
            stream.expect(Token::PUNCTUATION_TYPE, ',', 'Arguments must be separated by a comma')

            # if the comma above was a trailing comma, early exit the argument parse loop
            break if stream.test(Token::PUNCTUATION_TYPE, ')')
          end

          token = stream.expect(Token::NAME_TYPE, nil, 'An argument must be a name')
          name = Node::Expression::Variable::Local.new(token.value, parser.current_token.lineno)

          if (token = stream.next_if(Token::OPERATOR_TYPE, '=')) ||
             (token = stream.next_if(Token::PUNCTUATION_TYPE, ':'))
            default = parser.expression_parser.parse_expression
          else
            default = Node::Expression::Constant.new(nil, parser.current_token.lineno)
            default.attributes[:is_implicit] = true
          end

          unless check_constant_expression(default)
            raise Error::Syntax.new(
              'A default value for an argument must be a constant (a boolean, a string, a number, ' \
              'a sequence, or a mapping).',
              token.lineno,
              stream.source
            )
          end

          arguments.add_element(default, name)
        end

        stream.expect(Token::PUNCTUATION_TYPE, ')', 'A list of arguments must be closed by a parenthesis')

        arguments
      end

      # checks that the node only contains "constant" elements
      def check_constant_expression(node)
        return false unless node.is_a?(Node::Expression::Constant) ||
                            node.is_a?(Node::Expression::Array) ||
                            node.is_a?(Node::Expression::Hash) ||
                            node.is_a?(Node::Expression::Unary::Neg) ||
                            node.is_a?(Node::Expression::Unary::Pos)

        node.nodes.each_value do |n|
          return false unless check_constant_expression(n)
        end

        true
      end
    end
  end
end
