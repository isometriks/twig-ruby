# frozen_string_literal: true

module Twig
  module ExpressionParser
    module ParsesArguments
      private

      # @param [Parser] parser
      # @param [Integer] lineno
      def parse_callable_arguments(parser, lineno, parse_open_parenthesis: true)
        arguments = Node::Expression::Hash.new({}, lineno)

        parse_named_arguments(parser, parse_open_parenthesis:).nodes.each do |key, node|
          arguments.add_element(node, Node::Expression::Variable::Local.new(key, lineno))
        end

        arguments
      end

      # @param [Parser] parser
      def parse_named_arguments(parser, parse_open_parenthesis: true)
        args = AutoHash.new
        stream = parser.stream

        if parse_open_parenthesis
          stream.expect(Token::OPERATOR_TYPE, '(', 'A list of arguments must begin with an opening parenthesis')
        end

        has_spread = false

        until stream.test(Token::PUNCTUATION_TYPE, ')')
          unless args.empty?
            stream.expect(Token::PUNCTUATION_TYPE, ',', 'Arguments must be separated by a comma')

            # if above was trailing comma, exit early
            break if stream.test(Token::PUNCTUATION_TYPE, ')')
          end

          if stream.next_if(Token::OPERATOR_TYPE, '...')
            has_spread = true
            value = Node::Expression::Unary::Spread.new(parser.parse_expression, stream.current.lineno)
          elsif has_spread
            raise Error::Syntax.new(
              'Normal arguments must be placed before argument unpacking.',
              stream.current.lineno,
              stream.source
            )
          else
            value = parser.parse_expression
          end

          name = nil
          if value.is_a?(Node::Expression::Binary::SetBinary)
            name = value.nodes[:left].attributes[:name]
            value = value.nodes[:right]
          elsif (token = stream.next_if(Token::OPERATOR_TYPE, '=')) ||
                (token = stream.next_if(Token::PUNCTUATION_TYPE, ':'))
            # Allow quoted kwargs - form_with("data-turbo-stream": true)
            if value.is_a?(Node::Expression::Constant) && value.attributes[:value].is_a?(String)
              name = value.attributes[:value]
            elsif value.is_a?(Node::Expression::Name)
              name = value.attributes[:name]
            else
              raise Error::Syntax.new(
                "A parameter name must be a string, #{value.class.name} given.",
                token.lineno,
                stream.source
              )
            end

            value = parser.parse_expression
          end

          if name.nil?
            args.add(value)
          else
            args[name] = value
          end
        end

        stream.expect(Token::PUNCTUATION_TYPE, ')', 'A list of arguments must be closed by a parenthesis')

        Node::Nodes.new(args)
      end
    end
  end
end
