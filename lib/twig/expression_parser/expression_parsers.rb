# frozen_string_literal: true

module Twig
  module ExpressionParser
    class ExpressionParsers
      # @param [Array<Twig::ExpressionParser::Base>] parsers
      def initialize(parsers = [])
        @parsers_by_name = {}
        @parsers_by_class = {}

        add(parsers)
      end

      # @param [Array<Twig::ExpressionParser::Base>] parsers
      def add(parsers)
        parsers.each do |parser|
          if parser.precedence > 512 || parser.precedence.negative?
            raise(
              ArgumentError,
              "Precedence for \"#{parser.name}\" must be between 0 and 512, got #{parser.precedence}."
            )
          end

          parsers_by_name[parser.type] ||= {}
          parsers_by_class[parser.class.name] = parser

          parser.operator_tokens.each do |token|
            parsers_by_name[parser.type][token] = parser
          end
        end
      end

      # Yields each parser once, including those registered by class only,
      # such as the literal parser, which handles no operator token.
      def each(&)
        (parsers_by_name.values.flat_map(&:values) + parsers_by_class.values).uniq(&:object_id).each(&)
      end

      # @return [ExpressionParser::Base, nil]
      def by_class(klass)
        parsers_by_class[klass]
      end

      # @return [ExpressionParser::Base, nil]
      def by_name(type, name)
        parsers_by_name[type][name]
      end

      private

      # @return [Hash<Array<Twig::ExpressionParser::Base>>]]
      attr_reader :parsers_by_name

      # @return [Hash<Twig::ExpressionParser::Base>]
      attr_reader :parsers_by_class
    end
  end
end
