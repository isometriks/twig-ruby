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
          parsers_by_name[parser.type][parser.name] = parser
          parsers_by_class[parser.class.name] = parser

          parser.aliases.each do |alias_name|
            parsers_by_name[parser.type][alias_name] = parser
          end
        end
      end

      def each(&)
        parsers_by_name.values.map(&:values).flatten.each(&)
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
