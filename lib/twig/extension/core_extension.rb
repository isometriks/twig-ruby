module Twig
  module Extension
    class CoreExtension < Base
      def operators
        binary = Node::Expression::Binary
        
        [
          {
            # Unary
          },
          {
            '+': { precedence: 30, class: binary::AddBinary, associativity: ExpressionParser::OPERATOR_LEFT },
            '-': { precedence: 30, class: binary::SubBinary, associativity: ExpressionParser::OPERATOR_LEFT },
            '~': { precedence: 40, class: binary::ConcatBinary, associativity: ExpressionParser::OPERATOR_LEFT },
            '*': { precedence: 60, class: binary::MulBinary, associativity: ExpressionParser::OPERATOR_LEFT },
            '/': { precedence: 60, class: binary::DivBinary, associativity: ExpressionParser::OPERATOR_LEFT },
          }
        ]
      end

      def filters
        {
          capitalize: TwigFilter.new('capitalize', -> (string) { string.capitalize }),
        }
      end

      def token_parsers
        [
          TokenParser::Block.new,
          TokenParser::If.new,
        ]
      end
    end
  end
end
