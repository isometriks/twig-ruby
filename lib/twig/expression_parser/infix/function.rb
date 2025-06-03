# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Infix
      class Function < InfixExpressionParser
        include ParsesArguments

        def parse(parser, left, token)
          line = token.lineno

          unless left.is_a?(Node::Expression::Variable::Context)
            raise Error::Syntax.new(
              "Function name must be an identifier. got #{left.inspect}",
              line,
              parser.stream.source
            )
          end

          name = left.attributes[:name]

          if (aliased = parser.imported_symbol(:function, name))
            return Node::Expression::MacroReference.new(
              aliased[:node].nodes[:var],
              aliased[:name],
              parse_callable_arguments(parser, line, parse_open_parenthesis: false),
              line
            )
          end

          args = parse_named_arguments(parser, parse_open_parenthesis: false)
          function = parser.function(name, args, line)

          # Helper method returned
          if function.is_a?(Node::Expression::Base)
            return function
          end

          if (callable = function.parser_callable)
            fake_node = Node::Empty.new(line)
            fake_node.source_context = parser.stream.source

            return callable.call(parser, fake_node, args, line)
          end

          function.node_class.new(function, args, line)
        end

        def name
          '('
        end

        def description
          'Twig function call'
        end

        def precedence
          512
        end

        def associativity
          LEFT
        end
      end
    end
  end
end
