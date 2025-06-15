# frozen_string_literal: true

module Twig
  module Extension
    class Core < Base
      DEFAULT_TRIM_CHARS = " \t\n\r\0\x0B"

      class << self
        include ActiveSupport::NumberHelper
      end

      def initialize
        super

        @date_format = '%B %-e, %Y %H:%M'
        @number_format = [0, '.', ',']
      end

      attr_writer :number_format

      def expression_parsers
        unary = ExpressionParser::Prefix::Unary
        binary = ExpressionParser::Infix::Binary

        [
          # Unary operators
          unary.new(Node::Expression::Unary::Not, 'not', 70),
          unary.new(Node::Expression::Unary::Spread, '...', 512, description: 'Spread Operator'),
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
          binary.new(Node::Expression::Binary::BitwiseAnd, 'b-and', 16),
          binary.new(Node::Expression::Binary::Equal, '==', 20),
          binary.new(Node::Expression::Binary::NotEqual, '!=', 20),
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

          # All literals
          ExpressionParser::Prefix::Literal.new,
        ]
      end

      def filters
        [
          # Formatting filters
          TwigFilter.new('date', method(:format_date)),
          # TwigFilter.new('date_modify', $this->modifyDate(...)),
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
          TwigFunction.new('max', static(:max)),
          TwigFunction.new('min', static(:min)),
          TwigFunction.new('range', static(:range)),
          TwigFunction.new('constant', static(:constant)),
          TwigFunction.new('cycle', static(:cycle)),
          TwigFunction.new('date', method(:convert_date)),
          TwigFunction.new('include', static(:include), {
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
          # @todo: These should probably check enumerables etc. move to a method?
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
          TokenParser::Use.new,
          TokenParser::With.new,
          TokenParser::Yield.new,
        ]
      end

      def node_visitors
        [
          NodeVisitor::Spreader.new,
        ]
      end

      def format_date(date, format: nil, timezone: nil)
        format ||= @date_format

        convert_date(date, timezone:).strftime(format)
      end

      def convert_date(date = nil, timezone: nil)
        if date == 'now' || date.nil?
          date = DateTime.now
        elsif date.is_a?(Integer)
          date = Time.at(date).to_datetime
        end

        timezone ? date.in_time_zone(timezone) : date
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

      def number_format(number, decimal: nil, decimal_point: nil, thousands_separator: nil)
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

      def self.max(*args)
        args = args[0] if args&.length&.== 1
        args = args.values if args.is_a?(Hash)
        args.max
      end

      def self.min(*args)
        args = args[0] if args&.length&.== 1
        args = args.values if args.is_a?(Hash)
        args.min
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

        unless constant.include?('::')
          raise Error::Runtime, 'constant() expects string in format A::CONST'
        end

        class_name, _, constant = constant.rpartition('::')

        unless Object.const_defined?(class_name)
          return false if defined_test

          raise Error::Runtime, "Class #{class_name} does not exist"
        end

        klass = Object.const_get(class_name)

        unless klass.const_defined?(constant)
          return false if defined_test

          raise Error::Runtime, "Class #{class_name} does not have a constant #{constant}"
        end

        return true if defined_test

        klass.const_get(constant)
      end

      def self.cycle(values, position)
        unless values.respond_to?(:[])
          raise Error::Runtime, 'The "cycle" function only works with arrays'
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

      def self.strip_tags(string, tags: [])
        Sanitize.fragment(string || '', elements: tags)
      end

      def self.trim(string, character_mask: DEFAULT_TRIM_CHARS, side: :both)
        side = side.to_sym
        safe = string.html_safe?

        unless %i[left right both].include?(side)
          raise Error::Runtime, 'Trimming side must be "left", "right" or "both".'
        end

        if %i[left both].include?(side)
          string = string.gsub(/\A[#{Regexp.escape(DEFAULT_TRIM_CHARS)}]*/, '')
        end

        if %i[right both].include?(side)
          string = string.gsub(/[#{Regexp.escape(DEFAULT_TRIM_CHARS)}]*\z/, '')
        end

        safe && character_mask == DEFAULT_TRIM_CHARS ? string.html_safe : string
      end

      def self.nl2br(string)
        string.gsub("\n", "<br>\n")
      end

      def self.singularize(string, count = nil)
        string.singularize(count)
      end

      def self.pluralize(string, count = nil)
        string.pluralize(count)
      end

      def self.slug(string, separator: '-', locale: 'en')
        string.parameterize(separator:, locale:)
      end

      def self.join(value, glue: '', and_glue: nil)
        return value unless value.respond_to?(:to_a)

        value = value.values if value.is_a?(Hash)
        return '' if value.empty?

        return value.join(glue) if and_glue.nil? || and_glue == glue
        return value[0] if value.length == 1

        value[..-2].join(glue) + and_glue.to_s + value[-1].to_s
      end

      def self.split(charset, value, delimiter, limit: nil)
        value ||= ''

        unless delimiter == ''
          return limit.nil? ? value.split(delimiter) : value.split(delimiter, limit)
        end

        if limit <= 1
          return value.chars
        end

        length = value.length

        if limit.nil? || length < limit
          return [value]
        end

        [*0...length].map do |i|
          value[i, limit]
        end
      end

      # @param [Hash, Array, Enumerable] object
      def self.sort(object, arrow = nil)
        if arrow.nil?
          object.is_a?(Hash) ? object.sort.to_h : object.sort
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
        hash = object.is_a?(Array) ? object.each_with_index.to_h.invert : object
        size = count.ceil

        result = hash.each_slice(size).map do |slice|
          unless preserve_keys
            slice = [*0...size].zip(slice.to_h.values)
          end

          slice.to_h
        end

        return result if fill.nil?

        [*0...(size - result[-1].length)].each do
          result[-1][result[-1].length] = fill
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

      def self.array_every?(object, proc)
        unless object.respond_to?(:all?)
          raise Error::Runtime, "The \"has every\" test expects a sequence or a mapping, got \"#{object.class.name}\"."
        end

        object.all?(&proc)
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
        enumerable_function(object, :find, proc)
      end

      def self.reverse(object, preserve_keys: false)
        object.is_a?(Hash) ? object.to_a.reverse.to_h : object.reverse
      end

      def self.shuffle(object)
        object.is_a?(Hash) ? object.to_a.shuffle.to_h : object.shuffle
      end

      def self.length(object)
        object.length
      end

      def self.slice(object, start, length = nil, preserve_keys: false)
        if length.nil?
          object[start...]
        else
          object[start, length]
        end
      end

      def self.first(object)
        (object.is_a?(Hash) ? object.values : object).first
      end

      def self.last(object)
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

      def self.ensure_hash(value)
        return value if value.is_a?(Hash)

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

        a <=> b
      end

      # @todo some stuff missing here for Twig's custom compare
      def self.in_filter(value, object)
        return false unless object.respond_to?(:include?)

        if object.is_a?(String)
          return object.include?(value.to_s)
        end

        unless object.respond_to?(:any?)
          return false
        end

        object.any? do |k, v|
          (!v.nil? && compare(value, v)&.zero?) ||
            compare(value, k)&.zero? ||
            (value == false && in_filter(0, object)) ||
            (value == [] && in_filter(false, object)) ||
            (value == true && in_filter(1, object))
        end
      end

      def self.matches(regexp, string)
        Regexp.new(regexp).match?(string.to_s)
      rescue RegexpError => e
        raise Error::Runtime, "Invalid regular expression passed to matches: #{e.message}"
      end

      # @param [Environment] environment
      def self.get_attribute(
        environment, object, attribute, type, arguments: {}, defined_test: false, ignore_strict_check: false, &
      )
        if type == Template::ARRAY_CALL || object.respond_to?(:[])
          if object.respond_to?(:[]) && (
            (object.is_a?(Array) && attribute.is_a?(Integer) && attribute < object.length) ||
            (
              object.is_a?(Hash) && (
                object.key?(attribute) ||
                (attribute.respond_to?(:to_sym) && object.key?(attribute.to_sym))
              )
            )
          )
            return true if defined_test

            return object[attribute] || (attribute.is_a?(String) ? object[attribute.to_sym] : object[attribute.to_s])
          end

          if defined_test
            return false
          end

          if type == Template::ARRAY_CALL
            if ignore_strict_check || !environment.strict_variables?
              return
            end

            raise Error::Runtime, "Can't find key #{attribute} in #{object.inspect}."
          end
        end

        if object.respond_to?(attribute)
          if defined_test
            return true
          end

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

          if positional.length.positive? && kwargs.empty?
            object.send(attribute, *positional, &)
          elsif positional.empty? && kwargs.length.positive?
            object.send(attribute, **kwargs, &)
          elsif positional.length.positive? && kwargs.length.positive?
            object.send(attribute, *positional, **kwargs, &)
          else
            case object
            when Hash, Array
              object[attribute]
            else
              object.send(attribute, &)
            end
          end
        else
          if object.respond_to?(:[])
            return object[attribute]
          end

          return if ignore_strict_check || !environment.strict_variables?

          if defined_test
            return false
          end

          raise NotImplementedError, 'Need to implement other get_attribute calls'
        end
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
        object.nil? || object.empty?
      end

      # @param [Environment] environment
      # @param [Context] context
      def self.include(
        environment, context, template, variables = {}, with_context: true, ignore_missing: false, sandboxed: false
      )
        variables = if with_context
                      context.merge(variables)
                    else
                      context.only(variables)
                    end

        # @todo: Missing sandbox

        begin
          loaded = environment.resolve_template(template)
        rescue Error::Loader => e
          unless ignore_missing
            raise e
          end

          return ''
        end

        variables.buffer_and_return do
          loaded.render(variables)
        end
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
      def self.parse_loop_function(parser, fake_node, args, line)
        fake_function = TwigFunction.new('loop', ->(iterator) {})
        positional, = Util::CallableArgumentsExtractor.
          new(fake_node, fake_function, parser.environment).
          extract_arguments(args)

        recurse_args = Node::Expression::Array.new(AutoHash.new.add(
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
