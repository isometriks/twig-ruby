# frozen_string_literal: true

module Twig
  module Extension
    class Core < Base
      DEFAULT_TRIM_CHARS = " \t\n\r\0\x0B"

      # Returned by subscript_key when nothing matched. A sentinel rather than
      # nil, because nil is a perfectly good hash key and a perfectly good value.
      KEY_NOT_FOUND = Object.new.freeze

      class << self
        include ActiveSupport::NumberHelper
      end

      def initialize
        super

        @date_format = '%B %-e, %Y %H:%M'
        @number_format = [0, '.', ',']
      end

      attr_writer :date_format, :number_format, :timezone

      def expression_parsers
        unary = ExpressionParser::Prefix::Unary
        binary = ExpressionParser::Infix::Binary

        [
          # Unary operators
          unary.new(Node::Expression::Unary::Not, 'not', 70),
          ExpressionParser::Prefix::Spread.new,
          unary.new(Node::Expression::Unary::Neg, '-', 500),
          unary.new(Node::Expression::Unary::Pos, '+', 500),

          # Binary operators
          binary.new(
            Node::Expression::Binary::Elvis, '?:', 5, binary::RIGHT,
            description: 'Elvis operator (a ?: b)', aliases: ['? :']
          ),
          binary.new(
            Node::Expression::Binary::NullCoalesce, '??', 5, binary::RIGHT,
            description: 'Null coalescing operator (a ?? b)'
          ),
          binary.new(Node::Expression::Binary::Or, 'or', 10),
          binary.new(Node::Expression::Binary::Xor, 'xor', 12),
          binary.new(Node::Expression::Binary::And, 'and', 15),
          binary.new(Node::Expression::Binary::BitwiseOr, 'b-or', 16),
          binary.new(Node::Expression::Binary::BitwiseXor, 'b-xor', 17),
          binary.new(Node::Expression::Binary::BitwiseAnd, 'b-and', 18),
          binary.new(Node::Expression::Binary::Equal, '==', 20),
          binary.new(Node::Expression::Binary::NotEqual, '!=', 20),
          binary.new(Node::Expression::Binary::SameAs, '===', 20),
          binary.new(Node::Expression::Binary::NotSameAs, '!==', 20),
          binary.new(Node::Expression::Binary::Spaceship, '<=>', 20),
          binary.new(Node::Expression::Binary::Less, '<', 20),
          binary.new(Node::Expression::Binary::Greater, '>', 20),
          binary.new(Node::Expression::Binary::LessEqual, '<=', 20),
          binary.new(Node::Expression::Binary::GreaterEqual, '>=', 20),
          binary.new(Node::Expression::Binary::NotIn, 'not in', 20),
          binary.new(Node::Expression::Binary::In, 'in', 20),
          binary.new(Node::Expression::Binary::Matches, 'matches', 20),
          binary.new(Node::Expression::Binary::StartsWith, 'starts with', 20),
          binary.new(Node::Expression::Binary::EndsWith, 'ends with', 20),
          binary.new(Node::Expression::Binary::HasSome, 'has some', 20),
          binary.new(Node::Expression::Binary::HasEvery, 'has every', 20),
          binary.new(Node::Expression::Binary::Range, '..', 25),
          binary.new(Node::Expression::Binary::Add, '+', 30),
          binary.new(Node::Expression::Binary::Sub, '-', 30),
          binary.new(Node::Expression::Binary::Concat, '~', 27),
          binary.new(Node::Expression::Binary::Mul, '*', 60),
          binary.new(Node::Expression::Binary::Div, '/', 60),
          binary.new(Node::Expression::Binary::FloorDiv, '//', 60, description: 'Floor division'),
          binary.new(Node::Expression::Binary::Mod, '%', 60),
          binary.new(Node::Expression::Binary::Power, '**', 200, binary::RIGHT, description: 'Exponentiation operator'),

          # Ternary operator
          ExpressionParser::Infix::ConditionalTernary.new,

          # Twig callables
          ExpressionParser::Infix::Is.new,
          ExpressionParser::Infix::IsNot.new,
          ExpressionParser::Infix::Filter.new,
          ExpressionParser::Infix::Function.new,

          # Get attribute operators
          ExpressionParser::Infix::Dot.new,
          ExpressionParser::Infix::SquareBracket.new,

          # Group expression
          ExpressionParser::Prefix::Grouping.new,

          # Arrow function
          ExpressionParser::Infix::Arrow.new,

          # Assignment operator
          ExpressionParser::Infix::Assignment.new,

          # All literals
          ExpressionParser::Prefix::Literal.new,
        ]
      end

      def filters
        [
          # Formatting filters
          TwigFilter.new('date', method(:format_date)),
          TwigFilter.new('format', static(:sprintf)),
          TwigFilter.new('replace', static(:replace)),
          TwigFilter.new('number_format', method(:number_format), {
            argument_names: { thousands_separator: 'thousand_sep' },
          }),
          TwigFilter.new('abs', static(:abs)),
          TwigFilter.new('round', static(:round)),

          # Encoding
          TwigFilter.new('url_encode', static(:url_encode)),
          TwigFilter.new('json_encode', static(:json_encode)),
          TwigFilter.new('convert_encoding', static(:convert_encoding)),

          # Strings
          TwigFilter.new('title', static(:title_case)),
          TwigFilter.new('capitalize', static(:capitalize)),
          TwigFilter.new('upper', static(:upper)),
          TwigFilter.new('lower', static(:lower)),
          TwigFilter.new('striptags', static(:strip_tags), argument_names: { tags: 'allowable_tags' }),
          TwigFilter.new('trim', static(:trim)),
          TwigFilter.new('nl2br', static(:nl2br), { pre_escape: :html, is_safe: [:html] }),
          TwigFilter.new('plural', static(:pluralize)),
          TwigFilter.new('singular', static(:singularize)),
          TwigFilter.new('slug', static(:slug)),

          # array helpers
          TwigFilter.new('join', static(:join), argument_names: { and_glue: 'and' }),
          TwigFilter.new('split', static(:split), needs_charset: true),
          TwigFilter.new('sort', static(:sort)),
          TwigFilter.new('merge', static(:merge)),
          TwigFilter.new('batch', static(:batch), argument_names: { count: 'size' }),
          TwigFilter.new('column', static(:column)),
          TwigFilter.new('filter', static(:filter), argument_names: { proc: 'arrow' }),
          TwigFilter.new('map', static(:map), argument_names: { proc: 'arrow' }),
          TwigFilter.new('reduce', static(:reduce), argument_names: { proc: 'arrow' }),
          TwigFilter.new('find', static(:find), argument_names: { proc: 'arrow' }),

          # Arrays / Hashes filters
          TwigFilter.new('reverse', static(:reverse)),
          TwigFilter.new('shuffle', static(:shuffle)),
          TwigFilter.new('length', static(:length)),
          TwigFilter.new('slice', static(:slice)),
          TwigFilter.new('first', static(:first)),
          TwigFilter.new('last', static(:last)),

          # iteration and runtime
          TwigFilter.new('keys', static(:keys)),
          TwigFilter.new('values', static(:values)),
          TwigFilter.new('default', static(:default), {
            node_class: Node::Expression::Filter::Default,
          }),
          TwigFilter.new('invoke', static(:invoke)),
        ]
      end

      def functions
        [
          TwigFunction.new('parent', nil, {
            parser_callable: static(:parse_parent_function),
          }),
          TwigFunction.new('block', nil, {
            parser_callable: static(:parse_block_function),
          }),
          TwigFunction.new('loop', nil, {
            parser_callable: static(:parse_loop_function),
          }),
          TwigFunction.new('attribute', nil, {
            parser_callable: static(:parse_attribute_function),
          }),
          TwigFunction.new('max', static(:max)),
          TwigFunction.new('min', static(:min)),
          TwigFunction.new('range', static(:range)),
          TwigFunction.new('constant', static(:constant), argument_names: { defined_test: 'check_defined' }),
          TwigFunction.new('cycle', static(:cycle)),
          TwigFunction.new('random', static(:random), needs_charset: true),
          TwigFunction.new('date', method(:convert_date)),
          TwigFunction.new('include', static(:include), {
            needs_environment: true, needs_context: true, is_safe: [:all]
          }),
          TwigFunction.new('include_only', static(:include_only), {
            needs_environment: true, needs_context: true, is_safe: [:all]
          }),
          TwigFunction.new('source', static(:source), {
            needs_environment: true, is_safe: [:all]
          }),
        ]
      end

      def tests
        [
          TwigTest.new('even', nil, { node_class: Node::Expression::Test::Even }),
          TwigTest.new('odd', nil, { node_class: Node::Expression::Test::Odd }),
          TwigTest.new('defined', nil, { node_class: Node::Expression::Test::Defined }),
          TwigTest.new('same as', nil, {
            node_class: Node::Expression::Test::SameAs, one_mandatory_argument: true
          }),
          TwigTest.new('null', nil, { node_class: Node::Expression::Test::Null }),
          TwigTest.new('nil', nil, { node_class: Node::Expression::Test::Null }),
          TwigTest.new('none', nil, { node_class: Node::Expression::Test::Null }),
          TwigTest.new('divisible by', nil, {
            node_class: Node::Expression::Test::DivisibleBy, one_mandatory_argument: true
          }),
          TwigTest.new('constant', nil, { node_class: Node::Expression::Test::Constant }),
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
          TokenParser::Deprecated.new,
          TokenParser::Do.new,
          TokenParser::Embed.new,
          TokenParser::Extends.new,
          TokenParser::For.new,
          TokenParser::From.new,
          TokenParser::Guard.new,
          TokenParser::Macro.new,
          TokenParser::If.new,
          TokenParser::Import.new,
          TokenParser::Include.new,
          TokenParser::Set.new,
          TokenParser::Types.new,
          TokenParser::Use.new,
          TokenParser::With.new,
          TokenParser::Yield.new,
        ]
      end

      def node_visitors
        [
          NodeVisitor::Correctness.new,
        ]
      end

      def format_date(date, format: nil, timezone: self.timezone)
        format ||= @date_format

        convert_date(date, timezone:).strftime(format)
      end

      def convert_date(date = nil, timezone: self.timezone)
        if date == 'now' || date.nil?
          date = DateTime.now
        elsif date.is_a?(Integer)
          date = Time.then { |t| timezone == false ? t : t.zone }.at(date).to_datetime
        elsif date.is_a?(String)
          date = Time.then { |t| timezone == false ? t : t.zone }.parse(date)
        end

        timezone == false ? date : date.in_time_zone(timezone)
      end

      def timezone
        @timezone ||= Time.zone
      end

      def self.sprintf(string, *values)
        format(string || '', *values)
      end

      def self.replace(string, from)
        return if string.nil?

        unless from.is_a?(Hash) || from.is_a?(Array)
          raise Error::Runtime, "The \"replace\" filter expects a sequence or a mapping, got \"#{from.class}\"."
        end

        from = ensure_hash(from).to_h { |key, value| [key.to_s, value.to_s] }

        bytewise(string, *from.keys, *from.values) do |subject, *pairs|
          keys = pairs.first(from.length)

          subject.gsub(Regexp.union(*keys), keys.zip(pairs.drop(from.length)).to_h)
        end
      end

      def number_format(number, decimal: nil, decimal_point: nil, thousands_separator: nil)
        number = 0 if number.nil? || number == ''
        decimal ||= @number_format[0]
        decimal_point ||= @number_format[1]
        thousands_separator ||= @number_format[2]

        options = {
          precision: decimal,
          delimiter: thousands_separator,
          separator: decimal_point,
        }.compact

        self.class.number_to_delimited(
          self.class.number_to_rounded(number, options),
          options
        )
      end

      PHP_NUMERIC_STRING = /\A[ \t\n\r\v\f]*[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?[ \t\n\r\v\f]*\z/

      # PHP's abs takes an int or a float: null and false are 0, true is 1 and a
      # numeric string such as " -2.5" is its number, but any other string raises
      def self.abs(number)
        case number
        when nil, false then 0
        when true then 1
        when String
          unless number.match?(PHP_NUMERIC_STRING)
            raise TypeError, 'abs(): Argument #1 ($num) must be of type int|float, string given'
          end

          (number.match?(/[.eE]/) ? number.to_f : number.to_i).abs
        else
          number.abs
        end
      end

      # PHP's round, ceil and floor give a float. Rounded to decimal places,
      # this is a Float too, which prints as PHP prints it, -0 included. With
      # none, it is an Integer while PHP's int can hold it, so the result
      # works as a range bound, a key, a format argument or a string as in
      # PHP, where the float would show its .0 in Ruby. A negative value
      # rounded to zero is then 0, where PHP prints -0.
      def self.round(value, precision: 0, method: :common)
        value = value.to_f
        method = method.to_sym

        unless %i[common ceil floor].include?(method)
          raise Error::Runtime, 'The "round" filter only supports the "common", "ceil", and "floor" methods.'
        end

        return value unless value.finite?

        rounded = if method == :common
                    value.round(precision).to_f
                  else
                    (value * (10.0**precision)).public_send(method) / (10.0**precision)
                  end

        if !precision.positive? && rounded.abs < 2.0**63
          rounded.round
        elsif rounded.zero? && 1.0.fdiv(value).negative?
          -0.0
        else
          rounded
        end
      end

      # PHP's max and min compare values as its <=> does, and compare the
      # elements of one array the other way round from several arguments
      def self.max(value, *values)
        args = extremum_values('max', value, values)

        values.empty? ? Runtime::Comparison.max_of(args) : Runtime::Comparison.max(args)
      end

      def self.min(value, *values)
        args = extremum_values('min', value, values)

        values.empty? ? Runtime::Comparison.min_of(args) : Runtime::Comparison.min(args)
      end

      # PHP's max and min take a single array, or several values, and reject
      # a single scalar or an empty array rather than return null, which Twig
      # reports as a runtime error
      def self.extremum_values(name, value, values)
        return [value, *values] unless values.empty?

        args = value.is_a?(Hash) ? value.values : value
        # What filter returns for an Enumerable is a Traversable, which PHP's
        # max and min reject, rather than an array of its key/value pairs
        args = args.to_a if args.is_a?(Enumerable) && !args.is_a?(Runtime::EnumerableHash)

        unless args.is_a?(Array)
          raise ArgumentError, "#{name}(): Argument #1 ($value) must be of type array, #{php_type(args)} given"
        end

        raise ArgumentError, "#{name}(): Argument #1 ($value) must contain at least one element" if args.empty?

        args
      end

      # The type name PHP gives a value in a TypeError message
      def self.php_type(value)
        case value
        when nil then 'null'
        when true then 'true'
        when false then 'false'
        when Integer then 'int'
        when Float then 'float'
        when String, Symbol then 'string'
        else value.class.name
        end
      end

      # A sequence, as PHP's range() returns an array, so a range works
      # everywhere a sequence does: reverse, slice, [i], merge, json_encode
      # The type name PHP's get_debug_type gives a value
      def self.debug_type(value)
        [true, false].include?(value) ? 'bool' : php_type(value)
      end

      def self.range(low, high, step: 1)
        Range.new(low, high).step(step).to_a
      end

      # @param [String] constant
      # @param [Object, nil] object
      # @param [Boolean] defined_test
      def self.constant(constant, object = nil, defined_test: false)
        if object.nil?
          class_name, _, name = constant.rpartition('::')
          klass = class_name.empty? ? Kernel : constant_owner(class_name)
        else
          return defined_test ? true : object.class.name if constant == 'class'

          klass = object.class
          name = constant
          constant = "#{klass.name}::#{constant}"
        end

        holder = begin
          constant_holder(klass, name) unless klass.nil?
        rescue NameError
          nil
        end

        return !holder.nil? if defined_test
        return holder.const_get(name) if holder

        if constant.downcase.end_with?('::class')
          raise Error::Runtime, "You cannot use the Twig function \"constant\" to access \"#{constant}\". " \
                                'You could provide an object and call constant("class", $object) or use the ' \
                                'class name directly as a string.'
        end

        raise Error::Runtime, "Constant \"#{constant}\" is undefined."
      end

      # The class or module that holds klass::name as Ruby finds it: klass or
      # one of its ancestors, but not Object unless klass is Object, as PHP
      # finds only a class's own and inherited constants. A constant without
      # a class (klass is Kernel) is a global one.
      #
      # @return [Module, nil]
      def self.constant_holder(klass, name)
        return klass.const_defined?(name) ? klass : nil if klass.equal?(Kernel)

        stop = klass.equal?(Object) ? nil : Object
        klass.ancestors.take_while { |ancestor| !ancestor.equal?(stop) }.find do |ancestor|
          ancestor.const_defined?(name, false)
        end
      end

      # @return [Module, nil]
      def self.constant_owner(class_name)
        owner = Object.const_get(class_name)
        owner.is_a?(Module) ? owner : nil
      rescue NameError
        nil
      end

      def self.cycle(values, position)
        # A range or other sequence without [] is an array in PHP Twig, but
        # what filter returns for an Enumerable is a Traversable, which isn't
        values = values.to_a if values.is_a?(Enumerable) && !values.respond_to?(:[]) &&
                                !values.is_a?(Runtime::EnumerableHash)

        # Like PHP's array or ArrayAccess: a String or number has [] in Ruby,
        # but isn't a sequence to cycle through
        if !values.respond_to?(:[]) || [String, Symbol, Numeric, Proc, Method].any? { |type| values.is_a?(type) }
          raise Error::Runtime, 'The "cycle" function expects an array or "ArrayAccess" as first argument.'
        end

        unless values.respond_to?(:length)
          raise Error::Runtime, 'The "cycle" function expects a countable sequence as first argument.'
        end

        unless values.length.positive?
          raise Error::Runtime, 'The "cycle" function expects a non-empty sequence.'
        end

        values[position % values.length]
      end

      def self.url_encode(url)
        if url.respond_to?(:map)
          require 'uri'
          URI.encode_www_form(url || {}).gsub('+', '%20')
        else
          require 'cgi'
          CGI.escape(url || '').gsub('+', '%20')
        end
      end

      def self.json_encode(object)
        object = json_integers(object)

        object.respond_to?(:to_json) ? object.to_json : '{}'
      end

      # PHP's json_encode writes a float that has no fraction, below 1e17, as
      # an integer, so 3.0 is 3, 0.0 is 0 and -0.0 is -0
      def self.json_integers(object)
        case object
        when Float
          return JSON::Fragment.new('-0') if object.zero? && 1.0.fdiv(object).negative? && defined?(JSON::Fragment)

          object.finite? && object.abs < 1e17 && object == object.truncate ? object.to_i : object
        when Hash
          object.transform_values { |value| json_integers(value) }
        when Array
          object.map { |value| json_integers(value) }
        else
          object
        end
      end

      def self.convert_encoding(string, to, from)
        (string || '').to_s.encode(to, from)
      end

      def self.title_case(string)
        string&.titleize
      end

      def self.capitalize(string)
        return string&.capitalize unless invalid_string?(string)

        change_case(string[0], &:upcase) + change_case(string[1..], &:downcase)
      end

      def self.upper(string)
        change_case(string, &:upcase)
      end

      def self.lower(string)
        change_case(string, &:downcase)
      end

      # Changes the case of each character, keeping a byte that isn't valid in
      # the encoding of the string as it is, where String#upcase raises.
      def self.change_case(string, &)
        return string&.then(&) unless invalid_string?(string)

        string.chars.chunk(&:valid_encoding?).map { |valid, chars| valid ? yield(chars.join) : chars.join }.join
      end

      # Sanitize reads characters, so a byte that isn't one becomes U+FFFD.
      def self.strip_tags(string, tags: [])
        string = string.scrub if invalid_string?(string)

        Sanitize.fragment(string || '', elements: tags)
      end

      def self.trim(string, character_mask: DEFAULT_TRIM_CHARS, side: :both)
        return string if character_mask.nil? || character_mask.empty?
        return if string.nil?

        side = side.to_sym
        original = string
        safe = string.html_safe?

        unless %i[left right both].include?(side)
          raise Error::Runtime, 'Trimming side must be "left", "right" or "both".'
        end

        string = bytewise(string, character_mask) do |subject, mask|
          subject = subject.gsub(/\A[#{Regexp.escape(mask)}]*/, '') if %i[left both].include?(side)
          subject = subject.gsub(/[#{Regexp.escape(mask)}]*\z/, '') if %i[right both].include?(side)

          subject
        end

        return string unless safe && character_mask == DEFAULT_TRIM_CHARS

        # Trimmed escaped output is still only safe for its strategy
        original.is_a?(Runtime::Escaped) ? Runtime::Escaped.new(string, original.strategy) : string.html_safe
      end

      def self.nl2br(string)
        string.gsub("\n", "<br>\n")
      end

      def self.singularize(string, count = nil)
        string.singularize(count)
      end

      def self.pluralize(string, count = nil)
        bytewise(string) { |word| word.pluralize(count) }
      end

      def self.slug(string, separator: '-', locale: 'en')
        string.parameterize(separator:, locale:)
      end

      def self.join(value, glue: '', and_glue: nil)
        return value unless value.respond_to?(:to_a)

        value = value.values if value.respond_to?(:values)
        value = value.to_a if value.respond_to?(:to_a)
        value = value.map { |item| item.is_a?(Float) ? Runtime::StringCast.float(item) : item }

        return value.join(glue) if and_glue.nil? || and_glue == glue || value.empty?
        return value[0] if value.length == 1

        value[..-2].join(glue) + and_glue.to_s + value[-1].to_s
      end

      def self.split(charset, value, delimiter, limit: nil)
        value = value.to_s
        delimiter = delimiter.to_s

        return explode(delimiter, value, limit) unless delimiter == ''

        if limit.nil? || limit <= 1
          return split_into_characters(value, 'split')
        end

        length = value.length

        if limit.nil? || length < limit
          return [value]
        end

        (0...length).step(limit).map { |i| value[i, limit] }
      end

      # Splits like PHP's explode, which String#split doesn't: it keeps
      # trailing empty strings, splits on a literal space, gives [''] for an
      # empty string, takes a limit of 0 as 1 and drops -limit parts from the
      # end for a negative limit.
      def self.explode(delimiter, value, limit)
        limit = 1 if limit&.zero?
        parts = bytewise(value, delimiter) do |string, separator|
          string.split(Regexp.new(Regexp.escape(separator)), limit.nil? || limit.negative? ? -1 : limit)
        end
        parts = [''] if parts.empty?

        limit.nil? || limit.positive? ? parts : parts.first([parts.length + limit, 0].max)
      end

      # @param [Hash, Array, Enumerable] object
      def self.sort(object, arrow = nil)
        object = to_array(object)

        if arrow.nil?
          if object.is_a?(Hash)
            Runtime::Comparison.sort(object.to_a, &:last).to_h
          else
            Runtime::Comparison.sort(object.to_a)
          end
        elsif object.is_a?(Hash)
          # PHP's uasort compares the values and keeps their keys
          object.sort { |(_, a), (_, b)| arrow.call(a, b) }.to_h
        else
          object.sort { |a, b| arrow.call(a, b) }
        end
      end

      # Merges like PHP's [...$a, ...$b], into a new sequence or mapping, so
      # what the filter is applied to stays as it is: string keys are kept,
      # a later value replacing an earlier one, and integer keys are
      # renumbered after the items so far, so {1: 'a'}|merge({1: 'b'}) is
      # ['a', 'b'] and [1]|merge({a: 2}) is {0: 1, a: 2}.
      def self.merge(first, *rest)
        arrays = [first, *rest]
        arrays.each_with_index do |array, index|
          next if array.respond_to?(:each)

          raise Error::Runtime, "The \"merge\" filter expects a sequence or a mapping, got \"#{debug_type(array)}\" " \
                                "for argument #{index + 1}."
        end

        merged = Runtime::Spread.sequence(*arrays.map { |array| Runtime::Spread.new(array) })
        return merged unless merged.is_a?(Hash)

        # PHP has one key for :a and "a", so a later one replaces the value
        # where the first one is, under its name, as a HashWithIndifferentAccess
        # does, and the result is of the first one's class
        names = {}
        merged = merged.transform_keys { |key| names[key.is_a?(Symbol) ? key.to_s : key] ||= key }

        first.is_a?(Hash) && !first.instance_of?(Hash) ? first.class[merged] : merged
      end

      # Splits into rows of count items like PHP's array_chunk, which keeps
      # the keys only with preserve_keys, and fills the last row up to count
      # items with fill when it is given.
      #
      # @param [Array, Hash] object
      # @param [Integer, Float] count
      # @param [Object] fill
      # @param [Boolean] preserve_keys
      def self.batch(object, count, fill: nil, preserve_keys: true)
        return if object.nil?

        object = to_array(object)
        object = Runtime::EnumerableHash.traversable(object).to_array unless object.is_a?(Array) || object.is_a?(Hash)
        size = count.ceil

        rows = if preserve_keys
                 pairs = object.is_a?(Hash) ? object.to_a : object.each_with_index.map { |item, index| [index, item] }
                 pairs.each_slice(size).map { |row| AutoHash[row] }
               else
                 (object.is_a?(Hash) ? object.values : object).each_slice(size).to_a
               end

        if !fill.nil? && !rows.empty? && rows[-1].length < size
          missing = [fill] * (size - rows[-1].length)
          rows[-1] = rows[-1].is_a?(Array) ? rows[-1] + missing : rows[-1].add(*missing)
        end

        rows.map { |row| row.is_a?(Hash) ? array_from_hash(row) : row }
      end

      # The values of a column of the rows, like PHP's array_column: a row
      # without the column is left out, and with an index the values are keyed
      # by that column of their row, or added after the others when the row
      # has none. A name of null takes the whole rows.
      def self.column(object, name, index = nil)
        unless object.respond_to?(:each)
          raise Error::Runtime, "The \"column\" filter expects a sequence or a mapping, got \"#{debug_type(object)}\"."
        end

        result = AutoHash.new
        Runtime::EnumerableHash.traversable(object).each do |_key, row| # rubocop:disable Style/HashEachMethods
          value = name.nil? ? row : column_value(row, name)
          next if value.equal?(KEY_NOT_FOUND)

          key = index.nil? ? KEY_NOT_FOUND : column_value(row, index)
          key.equal?(KEY_NOT_FOUND) ? result.add(value) : result[column_key(key)] = value
        end

        array_from_hash(result)
      end

      # A row's value for a column of column, or KEY_NOT_FOUND. PHP reads an
      # object's public property, which for an object without [] is a public
      # reader of its own taking no arguments, such as a Data member or an
      # attr_reader, but not a method every object has, such as hash.
      def self.column_value(row, name)
        if row.is_a?(Hash) || row.is_a?(Array)
          key = subscript_key(row, name)

          return key.equal?(KEY_NOT_FOUND) ? key : row[key]
        end

        scalar = [nil, true, false].include?(row) ||
                 [String, Symbol, Numeric, Proc, Method].any? { |type| row.is_a?(type) }
        return KEY_NOT_FOUND if scalar
        return row[name] if row.respond_to?(:[])

        column_reader?(row, name) ? row.public_send(name) : KEY_NOT_FOUND
      end

      def self.column_reader?(row, name)
        return false unless (name.is_a?(String) || name.is_a?(Symbol)) && row.respond_to?(name)

        reader = row.method(name)
        [0, -1].include?(reader.arity) && ![Object, Kernel, BasicObject].include?(reader.owner)
      end

      # The key PHP makes of a value: true is 1, false 0, null "", a float is
      # truncated and a decimal string is its integer
      def self.column_key(value)
        case value
        when true then 1
        when false then 0
        when nil then ''
        when Float then value.to_i
        when String then Runtime::MappingKey.integer?(value) ? value.to_i : value
        else value
        end
      end

      # PHP's array_filter keeps the keys of an array, so a sequence with
      # items taken out is a mapping of the indexes that are left, as in
      # [1, 2, 3]|filter(v => v > 1), which is {1: 2, 2: 3}. Anything else is
      # filtered as a Traversable, an EnumerableHash.
      def self.filter(object, proc)
        result = enumerable_function(object, :filter, truthy_arrow(proc))

        case object
        when Hash then result.to_h
        when Array then result.to_array
        else result
        end
      end

      def self.map(object, proc)
        result = enumerable_function(object, :map, proc)

        if object.is_a?(Hash)
          object.keys.zip(result).to_h
        else
          result
        end
      end

      # Calls the arrow with the accumulator, then each value and its key, as
      # Twig does. A PHP closure ignores extra arguments, so the arrow can take
      # only the accumulator and the value, or only the accumulator.
      def self.reduce(object, proc, initial = nil)
        unless object.respond_to?(:each)
          raise Error::Runtime, "The \"reduce\" filter expects a sequence or a mapping, got \"#{debug_type(object)}\"."
        end

        Runtime::EnumerableHash.traversable(object).reduce(initial) do |accumulator, (key, value)|
          call_arrow(proc, accumulator, value, key)
        end
      end

      # Calls an arrow as PHP calls a closure, which ignores the arguments it
      # doesn't take
      def self.call_arrow(proc, *arguments)
        arguments = arguments.first(proc.arity) if proc.arity.between?(0, arguments.length)

        proc.call(*arguments)
      end

      # Whether the arrow is true for every value, which it gets with its key
      def self.array_every?(object, proc)
        unless object.respond_to?(:each)
          raise Error::Runtime, "The \"has every\" test expects a sequence or a mapping, got \"#{debug_type(object)}\"."
        end

        Runtime::EnumerableHash.traversable(object).all? do |key, value|
          Runtime::Truthiness.cast?(call_arrow(proc, value, key))
        end
      end

      # Whether the arrow is true for a value, which it gets with its key
      def self.array_some?(object, proc)
        unless object.respond_to?(:each)
          raise Error::Runtime, "The \"has some\" test expects a sequence or a mapping, got \"#{debug_type(object)}\"."
        end

        Runtime::EnumerableHash.traversable(object).any? do |key, value|
          Runtime::Truthiness.cast?(call_arrow(proc, value, key))
        end
      end

      def self.find(object, proc)
        enumerable_function(object, :find, truthy_arrow(proc))&.dig(1)
      end

      # Reverses like PHP's array_reverse, which keeps string keys, and integer
      # keys only with preserve_keys, or else the characters of a string
      def self.reverse(object, preserve_keys: false)
        return if object.nil?

        object = scalar_to_string(to_array(object))
        # String#reverse raises a bare ArgumentError on invalid bytes
        return split_into_characters(object, 'reverse').reverse.join if object.is_a?(String)

        object = Runtime::EnumerableHash.traversable(object).to_array unless object.is_a?(Array) || object.is_a?(Hash)
        return object.reverse if object.is_a?(Array) && !preserve_keys

        pairs = object.is_a?(Hash) ? object.to_a : object.each_with_index.map { |item, index| [index, item] }
        index = -1
        array_from_hash(pairs.reverse.to_h.transform_keys do |key|
          preserve_keys || !Runtime::MappingKey.integer?(key) ? key : index += 1
        end)
      end

      def self.shuffle(object)
        object = to_array(object)
        return split_into_characters(object, 'shuffle').shuffle.join if object.is_a?(String)

        object.is_a?(Hash) ? object.values.shuffle : object.shuffle
      end

      def self.length(object)
        return object.length if object.respond_to?(:length)
        return object.count if object.respond_to?(:count)
        return object.to_s.length unless object.method(:to_s).owner == Kernel

        1
      end

      # Slices a sequence or a mapping like PHP's array_slice, and anything
      # else like mb_substr: a negative start counts from the end, a start
      # before the beginning is the beginning, and a negative length leaves
      # that many items off the end. String keys are kept, and integer keys
      # only with preserve_keys.
      def self.slice(object, start, length = nil, preserve_keys: false)
        object = to_array(object)
        if !object.is_a?(Array) && !object.is_a?(Hash) && !object.is_a?(String) && object.respond_to?(:each)
          object = Runtime::EnumerableHash.traversable(object).to_array(preserve_keys:)
        end

        unless object.is_a?(Array) || object.is_a?(Hash)
          string = scalar_to_string(object).to_s
          offset, count = slice_bounds(string.length, start, length)

          return count.zero? ? '' : string[offset, count]
        end

        offset, count = slice_bounds(object.size, start, length)
        pairs = object.is_a?(Hash) ? object.to_a : object.each_with_index.map { |item, index| [index, item] }
        index = -1
        sliced = pairs[offset, count].to_h.transform_keys do |key|
          preserve_keys || !Runtime::MappingKey.integer?(key) ? key : index += 1
        end

        array_from_hash(sliced)
      end

      # The offset and the number of items that slice takes of size items
      #
      # @return [Array(Integer, Integer)]
      def self.slice_bounds(size, start, length)
        offset = start.to_i.negative? ? [size + start.to_i, 0].max : [start.to_i, size].min
        stop = if length.nil?
                 size
               elsif length.to_i.negative?
                 size + length.to_i
               else
                 [offset + length.to_i, size].min
               end

        [offset, [stop - offset, 0].max]
      end

      def self.first(object)
        return if object.nil?

        object = scalar_to_string(to_array(object))
        return object[0] if object.is_a?(String)

        (object.is_a?(Hash) ? object.values : object).first
      end

      def self.last(object)
        return if object.nil?

        object = scalar_to_string(to_array(object))
        return object[-1] if object.is_a?(String)

        (object.is_a?(Hash) ? object.values : object).last
      end

      # The keys of a sequence, a mapping or another Enumerable, and none for
      # anything else, such as a string or a number, as in PHP
      def self.keys(object)
        return object.keys if object.respond_to?(:keys)
        return (0...object.length).to_a if object.is_a?(Array)
        return [] unless object.respond_to?(:each)

        Runtime::EnumerableHash.traversable(object).keys
      end

      def self.values(object)
        return object.values if object.respond_to?(:values)

        object.to_a
      end

      def self.default(object, default = nil)
        present = object.respond_to?(:empty?) ? !object.empty? : !!object

        present ? object : default
      end

      def self.invoke(callable, *, **)
        callable.call(*, **)
      end

      # max is a keyword so that a template can name it without values, as in
      # random(max: 5), which Twig fills with the default of values
      def self.random(charset, values = nil, max: nil)
        if values.nil?
          return max.nil? ? rand : rand(0..max.to_i)
        end

        if values.is_a?(Integer) || values.is_a?(Float)
          if max.nil?
            if values.negative?
              max = 0
              min = values
            else
              max = values
              min = 0
            end
          else
            min = values
          end

          return rand(min.to_i..max.to_i)
        end

        if values.is_a?(String)
          return '' if values.empty?

          if charset != 'UTF-8'
            values = convert_encoding(values, 'UTF-8', charset)
          end

          values = split_into_characters(values, 'random')

          if charset != 'UTF-8'
            values = values.map { |value| convert_encoding(value, charset, 'UTF-8') }
          end
        end

        # Check if values is iterable (responds to each and has length/size)
        unless values.respond_to?(:each) && (values.respond_to?(:length) || values.respond_to?(:size))
          return values
        end

        # Convert to array if it's a hash or other enumerable
        values = values.is_a?(Hash) ? values.values : values.to_a

        if values.empty?
          raise Error::Runtime, 'The "random" function cannot pick from an empty sequence or mapping.'
        end

        values.sample
      end

      # Unicode version of str_split(), an empty string giving a single empty character.
      def self.split_into_characters(string, name)
        string = string.dup.force_encoding(Encoding::UTF_8) if string.encoding == Encoding::BINARY

        unless string.valid_encoding?
          raise Error::Runtime, "Unable to split the string passed to \"#{name}\" into characters: " \
                                'Malformed UTF-8 characters, possibly incorrectly encoded.'
        end

        characters = string.chars
        characters.empty? ? [''] : characters
      end

      # PHP's string functions read bytes, so a byte that isn't valid in the
      # encoding of the string, as in "a\xffb" from a template, is one like any
      # other to str_contains, explode, strtr or trim, where Ruby's String
      # methods raise or don't find it. Yields the strings as they are when
      # they are all valid, as bytes then give the same result, or else as
      # bytes, and gives any string the block returns the encoding of the
      # first one back.
      def self.bytewise(*strings)
        return yield(*strings) if strings.none? { |string| invalid_string?(string) }

        encoding = strings.find { |string| string.is_a?(String) }.encoding
        result = yield(*strings.map { |string| string.is_a?(String) ? string.b : string })

        with_encoding(result, encoding)
      end

      # @param [String, Array] value
      def self.with_encoding(value, encoding)
        case value
        when String then value.dup.force_encoding(encoding)
        when Array then value.map { |item| with_encoding(item, encoding) }
        else value
        end
      end

      # Whether value is a string with a byte its encoding doesn't allow.
      def self.invalid_string?(value)
        value.is_a?(String) && !value.valid_encoding?
      end

      # The array PHP's toArray makes of a value: what filter returns for an
      # enumerable that is not an Array or a Hash, the Traversable of PHP,
      # becomes an Array or a Hash; without preserve_keys, a mapping becomes
      # its values. Anything else is returned as it is, so an Enumerable such
      # as a lazy query keeps its own first or sort.
      #
      # @return [Object]
      def self.to_array(value, preserve_keys: true)
        case value
        when Runtime::EnumerableHash then value.to_array(preserve_keys:)
        when Hash then preserve_keys ? value : value.values
        else value
        end
      end

      # A PHP array held in a Hash, as a sequence when its keys are 0, 1, 2...
      # in order, as PHP calls such an array a list
      #
      # @return [Array, Hash]
      def self.array_from_hash(hash)
        hash.each_key.with_index.all? { |key, index| key.is_a?(Integer) && key == index } ? hash.values : hash
      end

      # What first, last and reverse read of a number, a boolean or a symbol:
      # the string PHP casts it to
      def self.scalar_to_string(value)
        case value
        when true then '1'
        when false then ''
        when Float then php_float_string(value)
        when Numeric, Symbol then value.to_s
        else value
        end
      end

      # A float as PHP's (string) casts it, to 14 significant digits: 12.0 is
      # "12", 0.1 + 0.2 is "0.3" and 1e20 is "1.0E+20"
      def self.php_float_string(value)
        return 'NAN' if value.nan?
        return value.positive? ? 'INF' : '-INF' if value.infinite?

        string = format('%.14G', value)
        return string unless string.include?('E')

        mantissa, exponent = string.split('E')
        mantissa += '.0' unless mantissa.include?('.')

        "#{mantissa}E#{exponent[0]}#{exponent[1..].to_i}"
      end

      def self.ensure_hash(value)
        return value.to_h if value.is_a?(Hash)

        AutoHash.new.add(*value)
      end

      def self.numeric?(value)
        Float(value, exception: false)
      end

      # Twig's CoreExtension::compare, which is PHP 8's <=>
      def self.compare(a, b)
        Runtime::Comparison.compare(a, b)
      end

      # Whether value is in object, as Twig's CoreExtension::inFilter decides:
      # a substring of a string, or equal to one of the values of a sequence
      # or mapping as == compares them, never one of its keys
      def self.in_filter(value, object)
        if object.is_a?(String)
          return false unless [String, Symbol, Integer, Float].any? { |type| value.is_a?(type) }

          needle = Runtime::StringCast.cast(value)

          return bytewise(object, needle) { |haystack, part| haystack.include?(part) }
        end

        values = case object
                 when Hash, Runtime::EnumerableHash then object.values
                 when Enumerable then object
                 else return false
                 end

        # An object is only found as the same object
        unless compared_in?(value)
          return values.any? { |item| Runtime::Identity.same?(value, item) }
        end

        values.any? { |item| compare(value, item).zero? }
      end

      # Whether in compares value with ==, as it does a PHP scalar or array
      def self.compared_in?(value)
        case value
        when nil, true, false, Numeric, String, Symbol, Array, Hash, Runtime::EnumerableHash, ::Range,
             Enumerator::ArithmeticSequence
          true
        else
          false
        end
      end

      PCRE_BRACKET_DELIMITERS = { '(' => ')', '[' => ']', '{' => '}', '<' => '>' }.freeze
      PCRE_MODIFIERS = { 'i' => Regexp::IGNORECASE, 'x' => Regexp::EXTENDED, 's' => Regexp::MULTILINE }.freeze
      # Only the boolean result matters to matches, so modifiers that change
      # captures or greediness, or that Onigmo always applies, can be ignored.
      # Ruby's ^ and $ are always line anchors, so m is the default and D
      # cannot be honoured. Onigmo always matches by character, so u only
      # decides whether a malformed subject raises.
      PCRE_IGNORED_MODIFIERS = %w[m D S U X J n].freeze

      def self.matches(regexp, string)
        regex, utf8 = parse_pcre(regexp)
        subject = string.to_s

        begin
          subject.match?(regex)
        rescue ArgumentError, Encoding::CompatibilityError
          # Only the u modifier makes preg_match check the subject's encoding.
          # Without it the bytes are read as they are, so stray ones are
          # replaced rather than rejected.
          if utf8
            raise Error::Runtime, "Regexp \"#{regexp}\" passed to \"matches\" failed: " \
                                  'Malformed UTF-8 characters, possibly incorrectly encoded.'
          end

          # A pattern of bytes, as in "/\xff/", matches the bytes of the subject
          return subject.b.match?(regex) if regex.encoding == Encoding::BINARY

          subject.dup.force_encoding(Encoding::UTF_8).scrub.match?(regex)
        end
      rescue Regexp::TimeoutError
        raise Error::Runtime, "Regexp \"#{regexp}\" passed to \"matches\" failed: Backtrack limit exhausted."
      rescue RegexpError => e
        raise Error::Runtime, "Regexp \"#{regexp}\" passed to \"matches\" is not valid: #{e.message}"
      end

      # Converts a PCRE pattern with delimiters and modifiers, as PHP's
      # preg_match takes it, into a Regexp. Raises RegexpError with PHP's
      # message for a malformed pattern.
      def self.pcre_to_regexp(pattern)
        parse_pcre(pattern).first
      end

      # @return [Array(Regexp, Boolean)] the Regexp, and whether the u modifier
      #   was given
      def self.parse_pcre(pattern)
        pattern = pattern.to_s.lstrip
        raise RegexpError, 'Empty regular expression' if pattern.empty?

        delimiter = pattern[0]
        if delimiter.match?(/[[:alnum:]\\\0]/)
          raise RegexpError, 'Delimiter must not be alphanumeric, backslash, or NUL'
        end

        closing = PCRE_BRACKET_DELIMITERS.fetch(delimiter, delimiter)
        depth = 1
        position = 1
        while position < pattern.length
          case pattern[position]
          when '\\'
            position += 1
          when closing
            depth -= 1
            break if depth.zero?
          when delimiter
            depth += 1
          end

          position += 1
        end

        if position >= pattern.length
          raise RegexpError, if closing == delimiter
                               "No ending delimiter '#{closing}' found"
                             else
                               "No ending matching delimiter '#{closing}' found"
                             end
        end

        options = 0
        anchored = false
        utf8 = false
        pattern[(position + 1)..].each_char do |modifier|
          if PCRE_MODIFIERS.key?(modifier)
            options |= PCRE_MODIFIERS[modifier]
          elsif modifier == 'A'
            anchored = true
          elsif modifier == 'u'
            utf8 = true
          elsif !PCRE_IGNORED_MODIFIERS.include?(modifier) && !modifier.match?(/[ \r\n]/)
            raise RegexpError, "Unknown modifier '#{modifier}'"
          end
        end

        body = pattern[1...position]
        # A newline ends a trailing comment in extended mode before the group closes
        body = "\\A(?:#{body}#{"\n" if options.anybits?(Regexp::EXTENDED)})" if anchored
        # Without u, PCRE reads the pattern as bytes, so a byte that isn't valid
        # UTF-8, as in "/\xff/" from a template, matches that byte
        body = body.b unless utf8 || body.valid_encoding?

        [Regexp.new(body, options), utf8]
      end

      # The key or index that +attribute+ matches on a subscriptable object, or
      # KEY_NOT_FOUND when it matches none.
      #
      # Returning the key rather than the value is the point: it lets the caller
      # subscript exactly once. Fetching first and testing the result instead —
      # as `object[attribute] || object[attribute.to_s]` did — can't tell a key
      # holding nil or false from a key that isn't there, so { 'billable' =>
      # false } came back as nil.
      #
      # @return [Object] the matching key, or KEY_NOT_FOUND
      def self.subscript_key(object, attribute)
        # PHP truncates a float key to an integer, so items[1.5] is items[1],
        # though a Ruby hash with that float key finds it
        if attribute.is_a?(Float) && attribute.finite?
          return attribute if !object.is_a?(Array) && object.respond_to?(:key?) && object.key?(attribute)

          attribute = attribute.to_i
        end

        if object.is_a?(Array)
          return KEY_NOT_FOUND unless attribute.is_a?(Integer)

          # Ruby indexes from the end with a negative, so -1 is the last element
          # while anything below -length is as absent as anything above length.
          in_bounds = attribute >= -object.length && attribute < object.length

          return in_bounds ? attribute : KEY_NOT_FOUND
        end

        return KEY_NOT_FOUND unless object.respond_to?(:key?)
        return attribute if object.key?(attribute)

        # A template writes h.foo, h['foo'] and h[:foo] for the same Ruby hash,
        # so both forms of the name count as a match.
        symbol = attribute.to_sym if attribute.respond_to?(:to_sym)
        return symbol if !symbol.nil? && object.key?(symbol)

        string = attribute.to_s if attribute.respond_to?(:to_s)
        return string if !string.nil? && object.key?(string)

        # PHP stores a decimal string key such as "5" as the integer 5, so
        # h["5"] finds the key that {5: ...} or {(n): ...} created
        integer = attribute.to_i if attribute.is_a?(String) && attribute.match?(/\A(?:0|-?[1-9]\d*)\z/)
        return integer if !integer.nil? && object.key?(integer)

        KEY_NOT_FOUND
      end

      # Names the keys that do exist rather than dumping the object, which for
      # anything the size of a request's parameters buries the one absent key
      # under everything else.
      #
      # @return [String]
      def self.key_not_found_message(object, attribute)
        keys = if object.is_a?(::Array)
                 (0...object.length).to_a
               elsif object.respond_to?(:keys)
                 object.keys
               end

        if keys&.empty? && (object.is_a?(::Array) || object.is_a?(::Hash))
          return "Key \"#{attribute}\" does not exist as the sequence/mapping is empty."
        end

        keys = keys ? " with keys \"#{keys.join(', ')}\"" : ''

        "Key \"#{attribute}\" for sequence/mapping#{keys} does not exist."
      end

      # The message for an attribute that isn't there, as Twig gives it for a
      # sequence, mapping or scalar (a "key" for x[k], a "method" for x.m()),
      # or nil for any other object.
      #
      # @return [String, nil]
      def self.missing_attribute_message(object, attribute, type)
        action = case type
                 when Template::ARRAY_CALL then 'access a key'
                 when Template::METHOD_CALL then 'invoke a method'
                 else 'access an attribute'
                 end

        case object
        when nil
          "Impossible to #{action} (\"#{attribute}\") on a null variable."
        when ::Array, ::Hash
          return key_not_found_message(object, attribute) unless type == Template::METHOD_CALL

          "Impossible to invoke a method (\"#{attribute}\") on a sequence/mapping."
        when true, false, Integer, Float, String, Symbol
          value = case object
                  when true then '1'
                  when false then ''
                  else object.to_s
                  end
          type_name = [true, false].include?(object) ? 'bool' : php_type(object)

          "Impossible to #{action} (\"#{attribute}\") on a #{type_name} variable (\"#{value}\")."
        end
      end

      # @param [Environment] environment
      def self.get_attribute(
        environment, source, object, attribute, type, arguments: {}, defined_test: false,
        ignore_strict_check: false, lineno: -1, &
      )
        if type == Template::ARRAY_CALL || object.respond_to?(:[])
          key = object.respond_to?(:[]) ? subscript_key(object, attribute) : KEY_NOT_FOUND

          unless key.equal?(KEY_NOT_FOUND)
            return true if defined_test

            return object[key]
          end

          if type == Template::ARRAY_CALL
            if defined_test
              return false
            end

            if ignore_strict_check || !environment.strict_variables?
              return
            end

            raise Error::Runtime.new(
              missing_attribute_message(object, attribute, type) || key_not_found_message(object, attribute),
              lineno,
              source
            )
          end
        end

        responds_to = begin
          object.respond_to?(attribute)
        rescue StandardError
          false
        end

        if responds_to
          if defined_test
            return true
          end

          # A method call compiles its arguments to a Hash keyed by position or
          # name, and attribute() passes them as a sequence or a mapping, which
          # is unpacked like a spread. Spreads are unpacked as PHP unpacks the
          # argument array it calls the method with.
          arguments = [Runtime::Spread.new(arguments)] unless arguments.nil? || arguments.is_a?(::Hash)
          positional, kwargs = Runtime::Spread.split_arguments(arguments || {}, overwrite: true)

          # public_send, not send: respond_to? above already excludes private and
          # protected methods, but an object with a loose respond_to_missing?
          # can report true for one. Templates only reach the public interface.
          # Collections dispatch methods like any other object: this is reached
          # only when the key/index lookup above did not match.
          object.public_send(attribute, *positional, **kwargs.transform_keys(&:to_sym), &)
        # Constant could be nil but we should return if we find it
        elsif (constant = get_constant(object, attribute.to_s)) && constant[0] == :found
          constant[1]
        else
          return if ignore_strict_check || !environment.strict_variables?

          if defined_test
            return false
          end

          message = if (missing = missing_attribute_message(object, attribute, type))
                      missing
                    elsif object.respond_to?(:[])
                      key_not_found_message(object, attribute)
                    else
                      "Impossible to access an attribute (\"#{attribute}\") on a #{object.class} " \
                        "variable (\"#{object}\")."
                    end

          raise Error::Runtime.new(
            message,
            lineno,
            source
          )
        end
      end

      def self.get_constant(object, attribute)
        object = object.class unless object.respond_to?(:const_defined?)

        if object.const_defined?(attribute)
          [:found, object.const_get(attribute)]
        else
          [:not_found]
        end
      rescue NameError
        [:not_found]
      end

      # Whether Twig counts a value as true, as PHP's (bool) cast does
      def self.bool(value)
        Runtime::Truthiness.true?(value)
      end

      # Reports a deprecation as Symfony's trigger_deprecation does for Twig:
      # the message comes after "Since package version: ".
      def self.trigger_deprecation(package, version, message)
        prefix = package.to_s.empty? && version.to_s.empty? ? '' : "Since #{package} #{version}: "

        report_deprecation("#{prefix}#{message}")
      end

      # Where every deprecation ends up
      def self.report_deprecation(message)
        puts "Deprecation Notice: #{message}"
      end

      def self.test_empty?(object)
        object = to_array(object)

        object.nil? ||
          (object == false) ||
          (object.respond_to?(:empty?) && object.empty?) ||
          (object.respond_to?(:length) && (object.length&.== 0)) || # rubocop:disable Style/ZeroLengthPredicate
          (object.respond_to?(:size) && (object.size&.== 0)) || # rubocop:disable Style/ZeroLengthPredicate
          (object.respond_to?(:to_s) && (object.to_s == ''))
      end

      # @param [Environment] environment
      # @param [Context] context
      def self.include(environment, context, template, variables = {}, with_context: true, ignore_missing: false)
        # PHP's array_merge takes only an array
        variables = Runtime::Context.variables(variables) do |type|
          ::TypeError.new("array_merge(): Argument #2 must be of type array, #{type} given")
        end

        variables = if with_context
                      context.merge(variables)
                    else
                      context.only(variables)
                    end

        begin
          loaded = environment.resolve_template(template)
        rescue Error::Loader => e
          unless ignore_missing
            raise e
          end

          return ''
        end

        rendered = variables.buffer_and_return do
          loaded.render(variables)
        end.to_s

        rendered.empty? ? '' : rendered.html_safe
      end

      # Unlike PHP, this needs the context: Context#only keeps the call context
      # (Rails view helpers) and the output buffer of the including template.
      #
      # @param [Environment] environment
      # @param [Context] context
      def self.include_only(environment, context, template, variables = {}, ignore_missing: false)
        include(environment, context, template, variables, with_context: false, ignore_missing:)
      end

      # @param [Environment] environment
      # @param [String] name
      # @param [Boolean] ignore_missing
      def self.source(environment, name, ignore_missing: false)
        environment.loader.get_source_context(name).code
      rescue Error::Loader => e
        raise e unless ignore_missing
      end

      # @param [Parser] parser
      # @param [Node::Base] fake_node
      def self.parse_parent_function(parser, fake_node, args, line)
        unless (block_name = parser.peek_block_stack)
          raise Error::Syntax.new(
            'Calling the "parent" function outside of a block is forbidden.',
            line,
            parser.stream.source
          )
        end

        unless parser.inheritance?
          raise Error::Syntax.new(
            'Calling the "parent" function on a template that does not call "extends" or "use" is forbidden.',
            line,
            parser.stream.source
          )
        end

        Node::Expression::Parent.new(block_name, line)
      end

      # @param [Parser] parser
      # @param [Node::Base] fake_node
      def self.parse_block_function(parser, fake_node, args, line)
        fake_function = TwigFunction.new('block', ->(name, template = nil) {})
        positional, = Util::CallableArgumentsExtractor.
          new(fake_node, fake_function, parser.environment).
          extract_arguments(args)

        Node::Expression::BlockReference.new(positional[0], positional[1], line)
      end

      # @param [Parser] parser
      # @param [Node::Base] fake_node
      def self.parse_attribute_function(parser, fake_node, args, line)
        fake_function = TwigFunction.new('attribute', ->(variable, attribute, arguments = nil) {})
        positional, = Util::CallableArgumentsExtractor.
          new(fake_node, fake_function, parser.environment).
          extract_arguments(args)

        Node::Expression::GetAttribute.new(positional[0], positional[1], positional[2], Template::ANY_CALL, line)
      end

      # @param [Parser] parser
      # @param [Node::Base] fake_node
      def self.parse_loop_function(parser, fake_node, args, line)
        fake_function = TwigFunction.new('loop', ->(iterator) {})
        positional, = Util::CallableArgumentsExtractor.
          new(fake_node, fake_function, parser.environment).
          extract_arguments(args)

        recurse_args = Node::Expression::Hash.new(AutoHash.new.add(
          Node::Expression::Constant.new(0, line),
          positional[0]
        ), line)
        expr = Node::Expression::GetAttribute.new(
          Node::Expression::Variable::Context.new('loop', line),
          Node::Expression::Constant.new('call', line),
          recurse_args,
          Template::METHOD_CALL,
          line
        )
        expr.attributes[:is_generator] = true
        expr = Node::Expression::Filter::Raw.new(expr)
        expr.attributes[:is_generator] = true

        expr
      end

      # An arrow that returns whether the given one's result is true, as PHP
      # casts it to bool, with the same number of arguments
      def self.truthy_arrow(arrow)
        case arrow.arity
        when 1 then ->(value) { Runtime::Truthiness.cast?(arrow.call(value)) }
        when 2 then ->(value, key) { Runtime::Truthiness.cast?(arrow.call(value, key)) }
        else arrow
        end
      end

      def self.enumerable_function(object, function, proc)
        enumerable = Runtime::EnumerableHash.from(object)

        case proc.arity
        when 1
          enumerable.public_send(function) do |_, value|
            proc.call(value)
          end
        when 2
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
