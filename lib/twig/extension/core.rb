module Twig
  module Extension
    class Core < Base
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
          capitalize: TwigFilter.new('capitalize', [self, :capitalize]),
          upper: TwigFilter.new('upper', [self, :upper]),
        }
      end

      def token_parsers
        [
          TokenParser::Block.new,
          TokenParser::Extends.new,
          TokenParser::If.new,
          TokenParser::Include.new,
        ]
      end

      def capitalize(string)
        string.capitalize
      end

      def upper(string)
        string.upcase
      end
    end
  end
end
