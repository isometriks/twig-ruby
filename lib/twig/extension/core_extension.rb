module Twig
  module Extension
    class CoreExtension < Extension
      def operators
        binary = Node::Expression::Binary
        
        [
          {
            # Unary
          },
          {
            '+': { precedence: 30, class: binary::AddBinary, associativity: ExpressionParser::OPERATOR_LEFT },
            '-': { precedence: 30, class: binary::SubBinary, associativity: ExpressionParser::OPERATOR_LEFT },
            '*': { precedence: 60, class: binary::MulBinary, associativity: ExpressionParser::OPERATOR_LEFT },
            '/': { precedence: 60, class: binary::DivBinary, associativity: ExpressionParser::OPERATOR_LEFT },
          }
        ]
      end

      def filters
        {
          capitalize: Filter.new('capitalize', -> (string) { string.capitalize }),
        }
      end
    end
  end
end
