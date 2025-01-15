# frozen_string_literal: true

module Twig
  module Extension
    class Core < Base
      def operators
        unary = Node::Expression::Unary
        binary = Node::Expression::Binary

        [
          {
            not: { precedence: 70, class: unary::Not },
            '-': { precedence: 500, class: unary::Neg },
            '+': { precedence: 500, class: unary::Pos },
          },
          {
            or: { precedence: 10, class: binary::Or, associativity: ExpressionParser::OPERATOR_LEFT },
            xor: { precedence: 12, class: binary::Xor, associativity: ExpressionParser::OPERATOR_LEFT },
            and: { precedence: 15, class: binary::And, associativity: ExpressionParser::OPERATOR_LEFT },

            '==': { precedence: 20, class: binary::Equal, associativity: ExpressionParser::OPERATOR_LEFT },
            '!=': { precedence: 20, class: binary::NotEqual, associativity: ExpressionParser::OPERATOR_LEFT },
            '<=>': { precedence: 20, class: binary::Spaceship, associativity: ExpressionParser::OPERATOR_LEFT },
            '<': { precedence: 20, class: binary::Less, associativity: ExpressionParser::OPERATOR_LEFT },
            '>': { precedence: 20, class: binary::Greater, associativity: ExpressionParser::OPERATOR_LEFT },
            '>=': { precedence: 20, class: binary::GreaterEqual, associativity: ExpressionParser::OPERATOR_LEFT },
            '<=': { precedence: 20, class: binary::LessEqual, associativity: ExpressionParser::OPERATOR_LEFT },

            '+': { precedence: 30, class: binary::Add, associativity: ExpressionParser::OPERATOR_LEFT },
            '-': { precedence: 30, class: binary::Sub, associativity: ExpressionParser::OPERATOR_LEFT },
            '~': { precedence: 40, class: binary::Concat, associativity: ExpressionParser::OPERATOR_LEFT },
            '*': { precedence: 60, class: binary::Mul, associativity: ExpressionParser::OPERATOR_LEFT },
            '/': { precedence: 60, class: binary::Div, associativity: ExpressionParser::OPERATOR_LEFT },
          },
        ]
      end

      def filters
        {
          capitalize: TwigFilter.new('capitalize', [self, :capitalize]),
          upper: TwigFilter.new('upper', [self, :upper]),
          lower: TwigFilter.new('lower', [self, :lower]),
          raw: TwigFilter.new('raw', [self, :raw]),
        }
      end

      def token_parsers
        [
          TokenParser::Block.new,
          TokenParser::Extends.new,
          TokenParser::If.new,
          TokenParser::Include.new,
          TokenParser::With.new,
          TokenParser::Yield.new,
        ]
      end

      def capitalize(string)
        string.capitalize
      end

      def upper(string)
        string.upcase
      end

      def lower(string)
        string.downcase
      end
    end
  end
end
