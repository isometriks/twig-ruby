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
          TwigFilter.new('number_format', method(:number_format)),
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
          TwigFilter.new('striptags', static(:strip_tags)),
          TwigFilter.new('trim', static(:trim)),
          TwigFilter.new('nl2br', static(:nl2br), { pre_escape: :html, is_safe: [:html] }),
          TwigFilter.new('plural', static(:pluralize)),
          TwigFilter.new('singular', static(:singularize)),
          TwigFilter.new('slug', static(:slug)),

          # array helpers
          TwigFilter.new('join', static(:join)),
          TwigFilter.new('split', static(:split), needs_charset: true),
          TwigFilter.new('sort', static(:sort)),
          TwigFilter.new('merge', static(:merge)),
          TwigFilter.new('batch', static(:batch)),
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
          TwigFunction.new('constant', static(:constant)),
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
          NodeVisitor::Spreader.new,
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

      def self.abs(number)
        number.abs
      end

      def self.round(value, precision: 0, method: :common)
        value = value.to_f
        method = method.to_sym

        return value.round(precision) if method == :common

        unless %i[ceil floor].include?(method)
          raise Error::Runtime, 'The "round" filter only supports the "common", "ceil", and "floor" methods'
        end

        rounded = (value * (10.0**precision)).public_send(method) / (10.0**precision)
        rounded = rounded.to_i unless precision.positive?

        rounded&.zero? ? 0 : rounded
      end

      def self.max(value, *values)
        extremum_values('max', value, values).max
      end

      def self.min(value, *values)
        extremum_values('min', value, values).min
      end

      # PHP's max and min take a single array, or several values, and reject
      # a single scalar or an empty array rather than return null, which Twig
      # reports as a runtime error
      def self.extremum_values(name, value, values)
        return [value, *values] unless values.empty?

        args = value.is_a?(Hash) ? value.values : value
        args = args.to_a if args.is_a?(Enumerable)

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

      def self.range(low, high, step: 1)
        Range.new(low, high).step(step)
      end

      # @param [String] constant
      # @param [Object, nil] object
      # @param [Boolean] defined_test
      def self.constant(constant, object = nil, defined_test: false)
        unless object.nil?
          if defined_test
            return object.class.const_defined?(constant)
          end

          return object.class.const_get(constant)
        end

        if constant.include?('::')
          class_name, _, constant = constant.rpartition('::')
        else
          class_name = Kernel.name
        end

        unless Object.const_defined?(class_name)
          return false if defined_test

          raise Error::Runtime, "Class #{class_name} does not exist."
        end

        klass = Object.const_get(class_name)

        unless klass.const_defined?(constant)
          return false if defined_test

          raise Error::Runtime, "Class #{class_name} does not have a constant #{constant}."
        end

        return true if defined_test

        klass.const_get(constant)
      end

      def self.cycle(values, position)
        # A range or other sequence without [] is an array in PHP Twig
        values = values.to_a if values.is_a?(Enumerable) && !values.respond_to?(:[])

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
        object.respond_to?(:to_json) ? object.to_json : '{}'
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

        return value.join(glue) if and_glue.nil? || and_glue == glue
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
        if arrow.nil?
          object.is_a?(Hash) ? object.sort { |a, b| a[1] <=> b[1] }.to_h : object.sort
        else
          object.sort { |a, b| arrow.call(a, b) }.then do |sorted|
            object.is_a?(Hash) ? sorted.to_h : sorted
          end
        end
      end

      def self.merge(first, *rest)
        if first.is_a?(Hash)
          [first, *rest].reduce(&:merge)
        else
          [first, *rest].reduce do |array, current|
            array.concat(current.respond_to?(:values) ? current.values : current)
          end
        end
      end

      # @param [Array, Hash] object
      # @param [Integer, Float] count
      # @param [Object] fill
      # @param [Boolean] preserve_keys
      def self.batch(object, count, fill: nil, preserve_keys: true)
        return if object.nil?

        hash = object.is_a?(Array) ? object.each_with_index.to_h { |k, v| [v, k] } : object
        size = count.ceil
        last_key = 0

        result = hash.each_slice(size).map do |slice|
          unless preserve_keys
            slice = [*0...size].zip(slice.to_h.values)
          end

          sliced_hash = slice.to_h
          last_key = sliced_hash.keys[-1]

          sliced_hash
        end

        if fill.nil? || result.empty?
          return result
        end

        result[-1] = AutoHash.new.merge(result[-1])

        [*0...(size - result[-1].length)].each do
          result[-1].add(fill)
        end

        result
      end

      def self.column(object, column)
        object.map { |o| o[column] }
      end

      def self.filter(object, proc)
        enumerable_function(object, :filter, proc)
      end

      def self.map(object, proc)
        result = enumerable_function(object, :map, proc)

        if object.is_a?(Hash)
          object.keys.zip(result).to_h
        else
          result
        end
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

      def self.array_every?(object, proc)
        unless object.respond_to?(:all?)
          raise Error::Runtime, "The \"has every\" test expects a sequence or a mapping, got \"#{object.class.name}\"."
        end

        if object.is_a?(Hash)
          object.each do |k, v|
            if proc.arity == 1
              return false unless proc.call(v)
            elsif !proc.call(v, k)
              return false
            end
          end

          true
        else
          object.all?(&proc)
        end
      end

      def self.array_some?(object, proc)
        unless object.respond_to?(:any?)
          raise Error::Runtime, "The \"has some\" test expects a sequence or a mapping, got \"#{object.class.name}\"."
        end

        if object.is_a?(Hash)
          object.each do |k, v|
            if proc.arity == 1
              return true if proc.call(v)
            elsif proc.call(v, k)
              return true
            end
          end

          false
        else
          object.any?(&proc)
        end
      end

      def self.find(object, proc)
        enumerable_function(object, :find, proc)&.dig(1)
      end

      def self.reverse(object, preserve_keys: false)
        return if object.nil?
        # String#reverse raises a bare ArgumentError on invalid bytes
        return split_into_characters(object, 'reverse').reverse.join if object.is_a?(String)

        object.is_a?(Hash) ? object.to_a.reverse.to_h : object.reverse
      end

      def self.shuffle(object)
        return split_into_characters(object, 'shuffle').shuffle.join if object.is_a?(String)

        object.is_a?(Hash) ? object.values.shuffle : object.shuffle
      end

      def self.length(object)
        return object.length if object.respond_to?(:length)
        return object.count if object.respond_to?(:count)
        return object.to_s.length unless object.method(:to_s).owner == Kernel

        1
      end

      def self.slice(object, start, length = nil, preserve_keys: false)
        if object.is_a?(Hash)
          object, keys = [object.values, object.keys]
          preserve_keys = true
        end

        values = length.nil? ? object[start...] : object[start, length]

        return values unless preserve_keys

        keys ||= [*0...object.length]
        keys = length.nil? ? keys[start...] : keys[start, length]
        keys.zip(values).to_h
      end

      def self.first(object)
        return if object.nil?
        return object[0] if object.is_a?(String)

        (object.is_a?(Hash) ? object.values : object).first
      end

      def self.last(object)
        return if object.nil?
        return object[-1] if object.is_a?(String)

        (object.is_a?(Hash) ? object.values : object).last
      end

      def self.keys(object)
        return object.keys if object.respond_to?(:keys)

        (0...object.length).to_a
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

      def self.random(charset, values = nil, max = nil)
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

      def self.ensure_hash(value)
        return value.to_h if value.is_a?(Hash)

        AutoHash.new.add(*value)
      end

      def self.numeric?(value)
        Float(value, exception: false)
      end

      def self.compare(a, b)
        trim_var = ->(value) { trim(value, character_mask: " \t\n\r\v\f") }

        if a.is_a?(Integer) && b.is_a?(String)
          b_trim = trim_var.call(b)

          unless numeric?(b_trim)
            return a.to_s <=> b
          end

          if b_trim.to_i.to_s == b_trim
            return a <=> b_trim.to_i
          else
            return a.to_f <=> b_trim.to_f
          end
        end

        if a.is_a?(String) && b.is_a?(Integer)
          a_trim = trim_var.call(a)

          unless numeric?(a_trim)
            return a <=> b.to_s
          end

          if a_trim.to_i.to_s == a_trim
            return a_trim.to_i <=> b
          else
            return a_trim.to_f <=> b.to_f
          end
        end

        if (a.is_a?(Float) || a.is_a?(Complex)) && b.is_a?(String)
          if a.is_a?(Complex)
            return 1
          end

          b_trim = trim_var.call(b)
          unless numeric?(b_trim)
            return a.to_s <=> b
          end

          return a <=> b_trim.to_f
        end

        if a.is_a?(String) && (b.is_a?(Float) || b.is_a?(Complex))
          if b.is_a?(Complex)
            return 1
          end

          a_trim = trim_var.call(a)
          unless numeric?(a_trim)
            return a <=> b.to_s
          end

          return a_trim.to_f <=> b
        end

        if a.is_a?(String) && b.is_a?(Symbol)
          return a <=> b.to_s
        end

        if a.is_a?(Symbol) && b.is_a?(String)
          return a.to_s <=> b
        end

        a <=> b
      end

      def self.in_filter(value, object)
        return false unless object.respond_to?(:include?)

        if object.is_a?(String)
          return bytewise(object, value.to_s) { |haystack, needle| haystack.include?(needle) }
        end

        unless object.respond_to?(:any?)
          return false
        end

        object.any? do |k, v|
          (!v.nil? && compare(value, v)&.zero?) ||
            compare(value, k)&.zero?
        end ||
          object.any? { |v| compare(value, v)&.zero? } ||
          (value == false && in_filter(0, object)) ||
          (value == [] && in_filter(false, object)) ||
          (value == true && in_filter(1, object))
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
        keys = object.respond_to?(:keys) ? " with keys \"#{object.keys.join(', ')}\"" : ''

        "Key \"#{attribute}\" for sequence/mapping#{keys} does not exist."
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
              key_not_found_message(object, attribute),
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

          # attribute() passes its arguments as a sequence, not as the keyed
          # hash a method call compiles to
          arguments = arguments.each_with_index.to_h { |v, i| [i, v] } if arguments.is_a?(::Array)
          arguments ||= {}

          positional = []
          arguments.each do |k, v|
            if !v.is_a?(Runtime::Spread) && k.is_a?(Integer)
              positional << v
            elsif v.is_a?(Runtime::Spread) && v.array?
              positional = [*positional, *v.value]
            end
          end

          kwargs = {}
          arguments.each do |k, v|
            if !v.is_a?(Runtime::Spread) && !k.is_a?(Integer)
              kwargs[k] = v
            elsif v.is_a?(Runtime::Spread) && v.hash?
              kwargs = kwargs.merge(v.value)
            end
          end

          kwargs = kwargs.transform_keys(&:to_sym)

          # public_send, not send: respond_to? above already excludes private and
          # protected methods, but an object with a loose respond_to_missing?
          # can report true for one. Templates only reach the public interface.
          if positional.length.positive? && kwargs.empty?
            object.public_send(attribute, *positional, &)
          elsif positional.empty? && kwargs.length.positive?
            object.public_send(attribute, **kwargs, &)
          elsif positional.length.positive? && kwargs.length.positive?
            object.public_send(attribute, *positional, **kwargs, &)
          else
            # Reached only when the object responds to the attribute and the
            # key/index lookup above did not match, so subscripting a Hash or
            # Array here could only ever miss — it raised TypeError on arrays
            # ({{ list.any? }}) and returned nil on hashes, silently rendering
            # nothing. Collections dispatch methods like any other object.
            object.public_send(attribute, &)
          end
        # Constant could be nil but we should return if we find it
        elsif (constant = get_constant(object, attribute.to_s)) && constant[0] == :found
          constant[1]
        else
          return if ignore_strict_check || !environment.strict_variables?

          if defined_test
            return false
          end

          message = if object.nil?
                      "Impossible to access an attribute (\"#{attribute}\") on a null variable."
                    elsif object.respond_to?(:[]) && !object.is_a?(String)
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

      # Zeroes are false in Twig
      def self.bool(value)
        if !value ||
           (value.respond_to?(:zero?) && value.zero?) ||
           value == ''
          false
        else
          true
        end
      end

      # @todo How to post deprecations? Also check if Rails is loaded and deprecate that way
      def self.deprecation_notice(message, template, line, package: nil, version: nil)
        package = package ? " (Package: #{package})" : ''
        version = version ? " (Version: #{version})" : ''

        puts "Deprecation Notice: #{message} in #{template} on line #{line}#{package}#{version}"
      end

      def self.test_empty?(object)
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
