# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class Is < InfixExpressionParser
        include ParsesArguments

        def parse(parser, left, token)
          stream = parser.stream
          test = parser.test(left.lineno)

          arguments = nil
          if stream.test(Token::OPERATOR_TYPE, '(')
            arguments = parse_named_arguments(parser)
          elsif test.one_mandatory_argument?
            arguments = Node::Nodes.new(AutoHash.new.add(
              parser.parse_expression(precedence)
            ))
          end

          if test.name == 'defined' && left.is_a?(Node::Expression::Variable::Context) &&
             !(aliased = parser.imported_symbol(:function, left.attributes[:name])).nil?
            left = Node::Expression::MacroReference.new(
              aliased[:node].nodes[:var],
              aliased[:name],
              Node::Expression::Array.new(AutoHash.new, left.lineno),
              left.lineno
            )
          end

          test.node_class.new(left, test, arguments, parser.current_token.lineno)
        end

        def name
          'is'
        end

        def description
          'Twig tests'
        end

        def precedence
          100
        end

        def associativity
          LEFT
        end
      end
    end
  end
end
