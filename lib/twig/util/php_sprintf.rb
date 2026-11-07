# frozen_string_literal: true

module Twig
  module Util
    # A port of PHP's sprintf (php_formatted_print), which differs from
    # Kernel#format in many ways: an exponent has no leading zeros, ' sets the
    # padding character, %u prints a negative number as unsigned, %d reads a
    # number at the start of a string, and arguments are converted the way
    # PHP converts them (PhpCast), and a float is rounded from its exact
    # binary value. Widths and precisions count bytes, as in PHP.
    class PhpSprintf
      INT_MAX = 2_147_483_647
      LONG_RANGE = 2**64
      FLOAT_PRECISION = 6
      MAX_FLOAT_PRECISION = 53
      # PHP's precision setting, which a float converted to a string has
      STRING_PRECISION = 14
      ARGNUM = /\G(\d+)\$/
      DIGITS = /\G\d+/

      # @param [String] format
      # @param [Array] args
      # @return [String]
      def self.call(format, *args)
        new(format, args).call
      end

      # A float as PHP converts it to a string, such as 1, 0.3 or 1.0E+20
      #
      # @param [Float] value
      # @return [String]
      def self.float_to_string(value)
        return 'NAN' if value.nan?
        return value.positive? ? 'INF' : '-INF' if value.infinite?

        general(value, STRING_PRECISION, 'E')
      end

      # PHP's zend_gcvt: the value with precision significant digits, in
      # exponential form when the exponent is below -4 or not below the
      # precision. A precision of -1 takes the fewest digits that read back as
      # the value.
      #
      # @param [Float] value
      # @param [Integer] precision
      # @param [String] exponent_char
      # @return [String]
      def self.general(value, precision, exponent_char)
        digits, point = precision == -1 ? shortest_digits(value) : digits(value, precision)
        threshold = precision == -1 ? 17 : precision
        sign = negative?(value) ? '-' : ''

        if point.negative? ? point < -3 : point > threshold
          exponent = point - 1
          mantissa = digits.length == 1 ? "#{digits}.0" : "#{digits[0]}.#{digits[1..]}"

          "#{sign}#{mantissa}#{exponent_char}#{exponent.negative? ? '-' : '+'}#{exponent.abs}"
        elsif point <= 0
          "#{sign}0.#{'0' * -point}#{digits}"
        elsif digits.length > point
          "#{sign}#{digits[0, point]}.#{digits[point..]}"
        else
          "#{sign}#{digits.ljust(point, '0')}"
        end
      end

      # Whether the float is negative, -0.0 included
      def self.negative?(value)
        value.negative? || (value.zero? && (1.0 / value).negative?)
      end

      # The significant digits of the value rounded to precision digits, with
      # trailing zeros removed, and the position of the decimal point, as
      # zend_dtoa gives them in mode 2
      #
      # @return [Array(String, Integer)]
      def self.digits(value, precision)
        digits, exponent = significant_digits(value, precision)
        digits = digits.sub(/0+\z/, '')

        digits.empty? ? ['0', 1] : [digits, exponent + 1]
      end

      # The exact binary value rounded to count significant digits, with a
      # tie going to the even digit, as zend_dtoa rounds it. Kernel#format
      # rounds a value just below a half up, so 2.675 (2.67499999...) would
      # give 2.68.
      #
      # @return [Array(String, Integer)] count digits, and the decimal
      #   exponent of the first one
      def self.significant_digits(value, count)
        rational = value.abs.to_r
        return ['0' * count, 0] if rational.zero?

        exponent = Math.log10(value.abs).floor
        exponent -= 1 while rational < Rational(10)**exponent
        exponent += 1 while rational >= Rational(10)**(exponent + 1)
        scaled = (rational * (Rational(10)**(count - 1 - exponent))).round(half: :even)

        # Rounding up to a power of ten, such as 9.99 to 10.0
        return ["1#{'0' * (count - 1)}", exponent + 1] if scaled == 10**count

        [scaled.to_s, exponent]
      end

      # The exact binary value rounded to precision decimals, with a tie
      # going to the even digit, as zend_dtoa rounds it in mode 3
      #
      # @return [String]
      def self.fixed(value, precision)
        digits = (value.abs.to_r * (10**precision)).round(half: :even).to_s
        return digits if precision.zero?

        digits = digits.rjust(precision + 1, '0')

        "#{digits[0...-precision]}.#{digits[-precision..]}"
      end

      # The fewest significant digits that read back as the value
      #
      # @return [Array(String, Integer)]
      def self.shortest_digits(value)
        return ['0', 1] if value.zero?

        mantissa, exponent = value.abs.to_s.split('e')
        whole, fraction = mantissa.split('.')
        leading_zeros = whole == '0' ? fraction[/\A0*/].length : 0
        digits = "#{whole}#{fraction}".sub(/\A0+/, '').sub(/0+\z/, '')
        point = whole == '0' ? -leading_zeros : whole.length

        [digits, point + exponent.to_i]
      end

      def initialize(format, args)
        @format = format.to_s
        @args = args
      end

      # @return [String]
      def call
        @source = @format.b
        @position = 0
        @next_arg = 0
        @max_missing = -1
        output = +''.b

        while @position < @source.bytesize
          percent = @source.index('%', @position)

          unless percent
            output << @source.byteslice(@position..)
            break
          end

          output << @source.byteslice(@position...percent)
          @position = percent + 1

          if byte == '%'
            output << '%'
            @position += 1
          else
            output << (specifier || '')
          end
        end

        if @max_missing >= 0
          raise ArgumentError, "#{@max_missing + 2} arguments are required, #{@args.length + 1} given"
        end

        output.force_encoding(@format.encoding)
      end

      private

      # The character at the current position, or nil at the end
      def byte
        @source.byteslice(@position)
      end

      # Reads a specifier after the %, and converts its argument
      #
      # @return [String, nil] nil when an argument is missing
      def specifier
        spec = { alignment: :right, padding: ' ', sign: false, width: 0, precision: nil }
        argnum = nil

        unless byte&.match?(/[a-zA-Z]/)
          if (match = @source.match(ARGNUM, @position))
            argnum = argument_number(match[1]) - 1
            @position = match.end(0)
          end

          flags(spec)

          spec[:width] = number(:width)
          return if spec[:width] == :missing

          if byte == '.'
            @position += 1
            spec[:precision] = number(:precision)
            return if spec[:precision] == :missing
          end
        end

        @position += 1 if byte == 'l'

        argnum ||= next_arg

        if argnum >= @args.length
          @max_missing = [@max_missing, argnum].max
          return
        end

        if spec[:precision] == -1 && !%w[g G h H].include?(byte)
          raise ArgumentError, 'Precision -1 is only supported for %g, %G, %h and %H'
        end

        convert(byte, @args[argnum], spec).tap { @position += 1 }
      end

      def flags(spec)
        loop do
          case byte
          when ' ', '0' then spec[:padding] = byte
          when '-' then spec[:alignment] = :left
          when '+' then spec[:sign] = true
          when "'"
            raise ArgumentError, 'Missing padding character' if @position + 1 >= @source.bytesize

            @position += 1
            spec[:padding] = byte
          else
            break
          end

          @position += 1
        end
      end

      def next_arg
        @next_arg.tap { @next_arg += 1 }
      end

      def argument_number(digits)
        number = digits.to_i
        return number if number.between?(1, INT_MAX)

        raise ArgumentError, "Argument number specifier must be greater than zero and less than #{INT_MAX}"
      end

      # A width or precision, written in the format or given by *, which
      # takes the next argument or the one its n$ names
      #
      # @return [Integer, nil, :missing] nil when no precision is written
      def number(key)
        name = key.to_s.capitalize

        if byte == '*'
          @position += 1

          if (match = @source.match(ARGNUM, @position))
            index = argument_number(match[1]) - 1
            @position = match.end(0)
          else
            index = next_arg
          end

          if index >= @args.length
            @max_missing = [@max_missing, index].max
            return :missing
          end

          return star(@args[index], key)
        end

        match = @source.match(DIGITS, @position)
        return key == :width ? 0 : nil unless match

        @position = match.end(0)
        raise ArgumentError, "#{name} must be greater than zero and less than #{INT_MAX}" if match[0].to_i > INT_MAX

        match[0].to_i
      end

      def star(value, key)
        raise ArgumentError, "#{key.to_s.capitalize} must be an integer" unless value.is_a?(Integer)

        if key == :width && !value.between?(0, INT_MAX)
          raise ArgumentError, "Width must be greater than zero and less than #{INT_MAX}"
        end

        if key == :precision && !value.between?(-1, INT_MAX)
          raise ArgumentError, "Precision must be between -1 and #{INT_MAX}"
        end

        value
      end

      def convert(specifier, value, spec)
        case specifier
        when 's'
          string = PhpCast.to_string(value).b
          string = string.byteslice(0, spec[:precision]) if spec[:precision]

          append(string, spec)
        when 'd'
          number = PhpCast.to_int(value)
          string = number.negative? ? number.to_s : "#{'+' if spec[:sign]}#{number}"

          append(string, integer_spec(spec), negative: number.negative?, sign: spec[:sign])
        when 'u'
          append((PhpCast.to_int(value) % LONG_RANGE).to_s, integer_spec(spec))
        when 'e', 'E', 'f', 'F', 'g', 'G', 'h', 'H'
          float(PhpCast.to_float(value), specifier, spec)
        when 'c'
          (PhpCast.to_int(value) % 256).chr
        when 'o' then base(value, 8, spec)
        when 'x' then base(value, 16, spec)
        when 'X' then base(value, 16, spec, upcase: true)
        when 'b' then base(value, 2, spec)
        when '%' then '%'
        when nil then raise ArgumentError, 'Missing format specifier at end of string'
        else raise ArgumentError, "Unknown format specifier \"#{specifier.dup.force_encoding(@format.encoding)}\""
        end
      end

      # php_sprintf_appendstring: pads to the width, on the right with the
      # padding character too, and on the left after the sign when the
      # padding is 0, where the first character is taken as the sign
      def append(string, spec, negative: false, sign: false)
        padding = spec[:padding] * [spec[:width] - string.bytesize, 0].max

        return string + padding if spec[:alignment] == :left
        return padding + string unless (negative || sign) && spec[:padding] == '0'

        (negative ? '-' : '+') + padding + string.byteslice(1..)
      end

      # An integer is never padded with 0 on the right
      def integer_spec(spec)
        spec[:alignment] == :left && spec[:padding] == '0' ? spec.merge(padding: ' ') : spec
      end

      # php_sprintf_append2n, which copies none of the digits when a
      # precision is given
      def base(value, base, spec, upcase: false)
        string = spec[:precision] ? '' : (PhpCast.to_int(value) % LONG_RANGE).to_s(base)

        append(upcase ? string.upcase : string, spec)
      end

      def float(number, specifier, spec)
        precision = [spec[:precision] || FLOAT_PRECISION, MAX_FLOAT_PRECISION].min

        unless number.finite?
          string = number.nan? ? 'NaN' : 'INF'

          return append(string, spec.merge(width: 0), negative: number.negative?, sign: spec[:sign])
        end

        if %w[e E f F].include?(specifier)
          negative = number.negative?
          string = if %w[e E].include?(specifier)
                     exponential(number.abs, precision, specifier)
                   else
                     self.class.fixed(number, precision)
                   end
        else
          negative = self.class.negative?(number)
          precision = 1 if precision.zero?
          string = self.class.general(number.abs, precision, specifier.match?(/[GH]/) ? 'E' : 'e')
        end

        string = "#{negative ? '-' : ('+' if spec[:sign])}#{string}"

        append(string, spec, negative:, sign: spec[:sign])
      end

      # php_conv_fp: the mantissa with precision decimals, and an exponent
      # without leading zeros
      def exponential(number, precision, specifier)
        digits, exponent = self.class.significant_digits(number, precision + 1)
        mantissa = precision.zero? ? digits : "#{digits[0]}.#{digits[1..]}"

        "#{mantissa}#{specifier}#{exponent.negative? ? '-' : '+'}#{exponent.abs}"
      end
    end
  end
end
