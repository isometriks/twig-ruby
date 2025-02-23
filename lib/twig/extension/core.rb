# frozen_string_literal: true

module Twig
  module Extension
    class Core < Base
      class << self
        include ActiveSupport::NumberHelper
      end

      def initialize
        super

        @date_format = '%B %-e, %Y %H:%M'
      end

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
            '? :': { precedence: 5, class: binary::Elvis, associativity: ExpressionParser::OPERATOR_RIGHT },
            '?:': { precedence: 5, class: binary::Elvis, associativity: ExpressionParser::OPERATOR_RIGHT },
            '??': { precedence: 5, class: binary::NullCoalesce, associativity: ExpressionParser::OPERATOR_RIGHT },
            or: { precedence: 10, class: binary::Or, associativity: ExpressionParser::OPERATOR_LEFT },
            xor: { precedence: 12, class: binary::Xor, associativity: ExpressionParser::OPERATOR_LEFT },
            and: { precedence: 15, class: binary::And, associativity: ExpressionParser::OPERATOR_LEFT },
            'b-or': { precedence: 16, class: binary::BitwiseOr, associativity: ExpressionParser::OPERATOR_LEFT },
            'b-xor': { precedence: 17, class: binary::BitwiseXor, associativity: ExpressionParser::OPERATOR_LEFT },
            'b-and': { precedence: 18, class: binary::BitwiseAnd, associativity: ExpressionParser::OPERATOR_LEFT },
            '==': { precedence: 20, class: binary::Equal, associativity: ExpressionParser::OPERATOR_LEFT },
            '!=': { precedence: 20, class: binary::NotEqual, associativity: ExpressionParser::OPERATOR_LEFT },
            '<=>': { precedence: 20, class: binary::Spaceship, associativity: ExpressionParser::OPERATOR_LEFT },
            '<': { precedence: 20, class: binary::Less, associativity: ExpressionParser::OPERATOR_LEFT },
            '>': { precedence: 20, class: binary::Greater, associativity: ExpressionParser::OPERATOR_LEFT },
            '>=': { precedence: 20, class: binary::GreaterEqual, associativity: ExpressionParser::OPERATOR_LEFT },
            '<=': { precedence: 20, class: binary::LessEqual, associativity: ExpressionParser::OPERATOR_LEFT },
            'not in': { precedence: 20, class: binary::NotIn, associativity: ExpressionParser::OPERATOR_LEFT },
            in: { precedence: 20, class: binary::In, associativity: ExpressionParser::OPERATOR_LEFT },
            matches: { precedence: 20, class: binary::Matches, associativity: ExpressionParser::OPERATOR_LEFT },
            'starts with': { precedence: 20, class: binary::StartsWith,
                             associativity: ExpressionParser::OPERATOR_LEFT },
            'ends with': { precedence: 20, class: binary::EndsWith, associativity: ExpressionParser::OPERATOR_LEFT },
            # 'has some': { precedence: 20, class: binary::HasSome, associativity: ExpressionParser::OPERATOR_LEFT },
            # 'has every': { precedence: 20, class: binary::HasEvery, associativity: ExpressionParser::OPERATOR_LEFT },
            '..': { precedence: 25, class: binary::Range, associativity: ExpressionParser::OPERATOR_LEFT },
            '~': { precedence: 27, class: binary::Concat, associativity: ExpressionParser::OPERATOR_LEFT },
            '+': { precedence: 30, class: binary::Add, associativity: ExpressionParser::OPERATOR_LEFT },
            '-': { precedence: 30, class: binary::Sub, associativity: ExpressionParser::OPERATOR_LEFT },
            '*': { precedence: 60, class: binary::Mul, associativity: ExpressionParser::OPERATOR_LEFT },
            '/': { precedence: 60, class: binary::Div, associativity: ExpressionParser::OPERATOR_LEFT },
            '//': { precedence: 60, class: binary::FloorDiv, associativity: ExpressionParser::OPERATOR_LEFT },
            '%': { precedence: 60, class: binary::Mod, associativity: ExpressionParser::OPERATOR_LEFT },
            is: { precedence: 100, associativity: ExpressionParser::OPERATOR_LEFT },
            'is not': { precedence: 100, associativity: ExpressionParser::OPERATOR_LEFT },
            '**': { precedence: 200, class: binary::Power, associativity: ExpressionParser::OPERATOR_RIGHT },
          },
        ]
      end

      def filters
        [
          # Formatting filters
          TwigFilter.new('date', method(:format_date)),
          # TwigFilter.new('date_modify', $this->modifyDate(...)),
          TwigFilter.new('format', static(:sprintf)),
          TwigFilter.new('replace', static(:replace)),
          TwigFilter.new('number_format', static(:number_format)),
          TwigFilter.new('abs', static(:abs)),
          TwigFilter.new('round', static(:round)),

          # Encoding
          # new TwigFilter('url_encode', self::urlencode(...)),
          TwigFilter.new('json_encode', static(:json_encode)),
          # new TwigFilter('convert_encoding', self::convertEncoding(...)),

          # Strings
          TwigFilter.new('title', static(:title_case)),
          TwigFilter.new('capitalize', static(:capitalize)),
          TwigFilter.new('upper', static(:upper)),
          TwigFilter.new('lower', static(:lower)),
          TwigFilter.new('trim', static(:trim)),
          TwigFilter.new('nl2br', static(:nl2br)),
          TwigFilter.new('plural', static(:pluralize)),
          TwigFilter.new('singular', static(:singularize)),
          TwigFilter.new('slug', static(:slug)),

          # array helpers
          # new TwigFilter('join', self::join(...)),
          # new TwigFilter('split', self::split(...), ['needs_charset' => true]),
          # new TwigFilter('sort', self::sort(...)),
          TwigFilter.new('merge', static(:merge)),
          # new TwigFilter('batch', self::batch(...)),
          TwigFilter.new('column', static(:column)),
          TwigFilter.new('filter', static(:filter)),
          TwigFilter.new('map', static(:map)),
          TwigFilter.new('reduce', static(:reduce)),
          TwigFilter.new('find', static(:find)),

          # Arrays / Hashes filters
          TwigFilter.new('reverse', static(:reverse)),
          TwigFilter.new('shuffle', static(:shuffle)),
          TwigFilter.new('length', static(:length)),
          TwigFilter.new('slice', static(:slice)),
          TwigFilter.new('first', static(:first)),
          TwigFilter.new('last', static(:last)),
        ]
      end

      def functions
        [
          TwigFunction.new('parent', nil, {
            parser_callable: static(:parse_parent_function),
          }),
          TwigFunction.new('max', static(:max)),
          TwigFunction.new('min', static(:min)),
          TwigFunction.new('range', static(:range)),
          TwigFunction.new('date', method(:convert_date)),
        ]
      end

      def tests
        [
          TwigTest.new('even', nil, { node_class: Node::Expression::Test::Even }),
          TwigTest.new('odd', nil, { node_class: Node::Expression::Test::Odd }),
          TwigTest.new('same as', nil, {
            node_class: Node::Expression::Test::SameAs, one_mandatory_argument: true
          }),
          TwigTest.new('null', nil, { node_class: Node::Expression::Test::Null }),
          TwigTest.new('nil', nil, { node_class: Node::Expression::Test::Null }),
          TwigTest.new('none', nil, { node_class: Node::Expression::Test::Null }),
          TwigTest.new('divisible by', nil, {
            node_class: Node::Expression::Test::DivisibleBy, one_mandatory_argument: true
          }),
          TwigTest.new('empty', static(:test_empty?)),
          TwigTest.new('iterable', nil, { node_class: Node::Expression::Test::Iterable }),
          TwigTest.new('sequence', nil, { node_class: Node::Expression::Test::Sequence }),
          TwigTest.new('mapping', nil, { node_class: Node::Expression::Test::Mapping }),
        ]
      end

      def token_parsers
        [
          TokenParser::Apply.new,
          TokenParser::Block.new,
          TokenParser::Do.new,
          TokenParser::Extends.new,
          TokenParser::For.new,
          TokenParser::If.new,
          TokenParser::Include.new,
          TokenParser::Set.new,
          TokenParser::With.new,
          TokenParser::Yield.new,
        ]
      end

      def format_date(date, format = nil, timezone = nil)
        format = @date_format if format.nil?

        convert_date(date, timezone).strftime(format)
      end

      def convert_date(date, timezone = nil)
        if date == 'now'
          date = DateTime.now
        end

        timezone.nil? ? date : date.in_time_zone(timezone)
      end

      def self.date_modify; end

      def self.sprintf(string, *values)
        format(string || '', *values)
      end

      def self.replace(string, from)
        unless from.is_a?(Hash)
          raise Error::Runtime, "String replacements must be a Hash #{from.class.name} given"
        end

        regex = Regexp.union(
          *from.keys.map(&:to_s)
        )

        string.gsub(regex, from.transform_keys(&:to_s))
      end

      def self.number_format(number, decimal = nil, decimal_point = nil, thousands_separator = nil)
        options = {
          precision: decimal,
          delimiter: thousands_separator,
          separator: decimal_point,
        }.compact

        number_to_delimited(
          number_to_rounded(number, options),
          options
        )
      end

      def self.abs(number)
        number.abs
      end

      def self.round(value, precision = 0, method = :common)
        value = value.to_f
        method = method.to_sym

        return value.round(precision) if method == :common

        unless %i[ceil floor].include?(method)
          raise Error::Runtime, 'The "round" filter only supports the "common", "ceil", and "floor" methods'
        end

        (value * (10.0**precision)).public_send(method) / (10.0**precision)
      end

      def self.max(*args)
        args.max
      end

      def self.min(*args)
        args.min
      end

      def self.range(start, finish, step = 1)
        Range.new(start, finish).step(step)
      end

      def self.json_encode(object)
        object.respond_to?(:to_json) ? object.to_json : '{}'
      end

      def self.title_case(string)
        string.titleize
      end

      def self.capitalize(string)
        string.capitalize
      end

      def self.upper(string)
        string.upcase
      end

      def self.lower(string)
        string.downcase
      end

      def self.trim(string)
        # @todo doesn't match php implementation
        string.strip
      end

      def self.nl2br(string)
        OutputBuffer.
          render(string).
          gsub("\n", "<br>\n").
          html_safe
      end

      def self.singularize(string, count = nil)
        string.singularize(count)
      end

      def self.pluralize(string, count = nil)
        string.pluralize(count)
      end

      def self.slug(string, separator = '-', locale = 'en')
        string.parameterize(separator:, locale:)
      end

      def self.merge(*enumerables)
        if enumerables.first.is_a?(Hash)
          enumerables.reduce(&:merge)
        else
          enumerables.reduce(&:concat)
        end
      end

      def self.column(object, column)
        object.map { |o| o[column] }
      end

      def self.filter(object, proc)
        enumerable_function(object, :filter, proc)
      end

      def self.map(object, proc)
        enumerable_function(object, :map, proc)
      end

      def self.reduce(object, proc, initial = nil)
        accumulator = initial

        case proc.arity
        when 2
          (object.is_a?(Hash) ? object.values : object).each do |value|
            accumulator = proc.call(accumulator, value)
          end
        when 3
          (object.is_a?(Hash) ? object : object.each_with_index).each do |key, value|
            accumulator = proc.call(accumulator, value, key)
          end
        else
          raise Error::Runtime, "Reduce takes 2 or 3 arguments, given #{proc.arity}."
        end

        accumulator
      end

      def self.find(object, proc)
        enumerable_function(object, :find, proc)
      end

      def self.reverse(object)
        object.is_a?(Hash) ? object.to_a.reverse.to_h : object.reverse
      end

      def self.shuffle(object)
        object.is_a?(Hash) ? object.to_a.shuffle.to_h : object.shuffle
      end

      def self.length(object)
        object.length
      end

      def self.slice(object, start, length)
        object[start, length]
      end

      def self.first(object)
        (object.is_a?(Hash) ? object.values : object).first
      end

      def self.last(object)
        (object.is_a?(Hash) ? object.values : object).last
      end

      def self.ensure_hash(value)
        return value if value.is_a?(Hash)

        AutoHash.new.add(*value)
      end

      # @todo some stuff missing here for Twig's custom compare
      def self.in_filter(value, compare)
        if compare.is_a?(String) || compare.is_a?(Integer) || compare.is_a?(Float)
          compare.to_s.include?(value.to_s)
        elsif compare.respond_to?(:include?)
          compare.include?(value)
        else
          false
        end
      end

      def self.matches(regexp, string)
        Regexp.new(regexp).match?(string.to_s)
      rescue RegexpError => e
        raise Error::Runtime, "Invalid regular expression passed to matches: #{e.message}"
      end

      def self.get_attribute(object, attribute, type, arguments: {}, &)
        if type == Template::ARRAY_CALL
          object[attribute] || (attribute.is_a?(String) ? object[attribute.to_sym] : object[attribute.to_s])
        elsif object.respond_to?(attribute)
          positional, kwargs = arguments.partition { |k, _v| k.is_a?(Integer) }.map(&:to_h)

          if positional.length.positive? && kwargs.empty?
            object.send(attribute, *positional.values, &)
          elsif positional.empty? && kwargs.length.positive?
            object.send(attribute, **kwargs, &)
          elsif positional.length.positive? && kwargs.length.positive?
            object.send(attribute, *positional.values, **kwargs, &)
          else
            object.send(attribute, &)
          end
        else
          raise NotImplementedError, 'Need to implement other get_attribute calls'
        end
      end

      def self.test_empty?(object)
        object.nil? || object.empty?
      end

      # @param [Parser] parser
      # @param [Node::Base] fake_node
      def self.parse_parent_function(parser, fake_node, args, line)
        unless (block_name = parser.peek_block_stack)
          raise Error::Syntax.new(
            'Calling the "parent" function outside of a block is forbidden',
            line,
            parser.stream.source
          )
        end

        unless parser.inheritance?
          raise Error::Syntax.new(
            'Calling the "parent" function on a template that does not call "extends" or "use" is forbidden',
            line,
            parser.stream.source
          )
        end

        Node::Expression::Parent.new(block_name, line)
      end

      def self.enumerable_function(object, function, proc)
        case proc.arity
        when 1
          enumerable = object.is_a?(Hash) ? object.values : object
          enumerable.public_send(function) do |value|
            proc.call(value)
          end
        when 2
          enumerable = object.is_a?(Hash) ? object : AutoHash.new.add(object)
          enumerable.public_send(function) do |key, value|
            proc.call(value, key)
          end
        else
          raise Error::Runtime, "The #{function.to_s.capitalize} method takes 1 or 2 arguments, given #{proc.arity}."
        end
      end
    end
  end
end
