# frozen_string_literal: true

module Twig
  module ExpressionParser
    module ParsesArguments
      private

      # @param [Parser] parser
      # @param [Integer] lineno
      # @param [Boolean] preserve_names Key named arguments by their name as written, rather than
      #   as a variable (which prefixes reserved names such as "blocks"); macro calls need this
      def parse_callable_arguments(parser, lineno, parse_open_parenthesis: true, preserve_names: false)
        arguments = Node::Expression::Hash.new({}, lineno)

        parse_named_arguments(parser, parse_open_parenthesis:).nodes.each do |key, node|
          key = if preserve_names
                  Node::Expression::Constant.new(key, lineno)
                else
                  Node::Expression::Variable::Local.new(key, lineno)
                end

          arguments.add_element(node, key)
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

          name = nil
          if stream.next_if(Token::OPERATOR_TYPE, '...')
            has_spread = true
            value = Node::Expression::Unary::Spread.new(parser.parse_expression, stream.current.lineno)
          elsif has_spread
            raise Error::Syntax.new(
              'Normal arguments must be placed before argument unpacking.',
              stream.current.lineno,
              stream.source
            )
          elsif stream.test(Token::STRING_TYPE) && stream.look(1).test(Token::OPERATOR_TYPE, '=')
            # Quoted kwargs with = - form_with("data-turbo-stream" = true). Parsed as an
            # expression, the = would try to assign to the string
            name = stream.next.value
            stream.next
            value = parser.parse_expression
          else
            value = parser.parse_expression
          end

          if name
            # Named by a quoted kwarg above
          elsif value.is_a?(Node::Expression::Binary::SetBinary)
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
