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

            # @todo this needs a custom class but just needs to be parsed as operaor for for loops
            in: { precedence: 20, class: binary::LessEqual, associativity: ExpressionParser::OPERATOR_LEFT },

            '+': { precedence: 30, class: binary::Add, associativity: ExpressionParser::OPERATOR_LEFT },
            '-': { precedence: 30, class: binary::Sub, associativity: ExpressionParser::OPERATOR_LEFT },
            '~': { precedence: 40, class: binary::Concat, associativity: ExpressionParser::OPERATOR_LEFT },
            '*': { precedence: 60, class: binary::Mul, associativity: ExpressionParser::OPERATOR_LEFT },
            '/': { precedence: 60, class: binary::Div, associativity: ExpressionParser::OPERATOR_LEFT },
          },
        ]
      end

      def filters
        [
          # Strings
          TwigFilter.new('title', method(:title_case)),
          TwigFilter.new('capitalize', method(:capitalize)),
          TwigFilter.new('upper', method(:upper)),
          TwigFilter.new('lower', method(:lower)),
          TwigFilter.new('trim', method(:trim)),
          TwigFilter.new('nl2br', method(:nl2br)),
          TwigFilter.new('pluralize', method(:pluralize)),
          TwigFilter.new('singularize', method(:singularize)),

          # Arrays / Hashes
          TwigFilter.new('reverse', method(:reverse)),
          TwigFilter.new('shuffle', method(:shuffle)),
          TwigFilter.new('length', method(:length)),
          TwigFilter.new('slice', method(:slice)),
          TwigFilter.new('first', method(:first)),
          TwigFilter.new('last', method(:last)),
        ]
      end

      def token_parsers
        [
          TokenParser::Block.new,
          TokenParser::Do.new,
          TokenParser::Extends.new,
          TokenParser::For.new,
          TokenParser::If.new,
          TokenParser::Include.new,
          TokenParser::Set.new,
          TokenParser::Yield.new,
        ]
      end

      def title_case(string)
        string.titleize
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

      def trim(string)
        # @todo doesn't match php implementation
        string.strip
      end

      def nl2br(string)
        OutputBuffer.
          render(string).
          gsub("\n", "<br>\n").
          html_safe
      end

      def singularize(string)
        string.singularize
      end

      def pluralize(string)
        string.pluralize
      end

      def reverse(object)
        object.is_a?(Hash) ? object.to_a.reverse.to_h : object.reverse
      end

      def shuffle(object)
        object.is_a?(Hash) ? object.to_a.shuffle.to_h : object.shuffle
      end

      def length(object)
        object.length
      end

      def slice(object, start, length)
        object[start, length]
      end

      def first(object)
        (object.is_a?(Hash) ? object.values : object).first
      end

      def last(object)
        (object.is_a?(Hash) ? object.values : object).last
      end

      def self.ensure_hash(value)
        return value if value.is_a?(Hash)

        AutoHash.new.add(*value)
      end

      def self.get_attribute(object, attribute, type, arguments: {})
        if type == Template::ARRAY_CALL
          object[attribute] || (attribute.is_a?(String) ? object[attribute.to_sym] : object[attribute.to_s])
        elsif object.respond_to?(attribute)
          positional, kwargs = arguments.partition { |k, _v| k.is_a?(Integer) }.map(&:to_h)

          if positional.length.positive? && kwargs.empty?
            object.send(attribute, *positional.values)
          elsif positional.empty? && kwargs.length.positive?
            object.send(attribute, **kwargs)
          elsif positional.length.positive? && kwargs.length.positive?
            object.send(attribute, *positional.values, **kwargs)
          else
            object.send(attribute)
          end
        else
          raise NotImplementedError, 'Need to implement other get_attribute calls'
        end
      end
    end
  end
end
