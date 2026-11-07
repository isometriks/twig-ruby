# frozen_string_literal: true

module Twig
  module Runtime
    class Escaper
      def initialize(charset)
        @charset = charset
      end

      JS_SHORT_MAP = {
        '\\' => '\\\\',
        '/' => '\\/',
        "\x08" => '\b',
        "\x0C" => '\f',
        "\x0A" => '\n',
        "\x0D" => '\r',
        "\x09" => '\t',
      }.freeze

      STRATEGIES = %i[html js url css html_attr html_attr_relaxed].freeze

      # charset and autoescape are keywords so that a template can name one
      # without the arguments before it, as in e(autoescape: true), which
      # Twig fills with their defaults
      def escape(string, strategy = :html, charset: nil, autoescape: false)
        strategy = strategy.to_sym

        # Markup (an html_safe string such as a capture, a macro result or a
        # Rails SafeBuffer) gets through without escaping, whatever the
        # strategy, like in Twig. The output of an escaping strategy only gets
        # through for a strategy it is safe for: Twig's escape filter returns a
        # plain string, which is escaped again.
        if autoescape && string.html_safe? && (!string.is_a?(Escaped) || string.safe_for?(strategy))
          return string
        end

        Escaped.new(escape_string(string, strategy, charset), strategy)
      end

      private

      def escape_string(string, strategy, charset)
        string = StringCast.cast(string)

        case strategy
        when :html
          escape_html(string.to_s, charset || @charset)
        when :html_attr
          escape_html_attr(string.to_s, charset || @charset)
        when :html_attr_relaxed
          escape_html_attr_relaxed(string.to_s, charset || @charset)
        when :js
          escape_js(string.to_s, charset || @charset)
        when :css
          escape_css(string.to_s, charset || @charset)
        when :url
          Extension::Core.rawurlencode(string)
        else
          raise Error::Runtime, "Invalid escaping strategy \"#{strategy}\" " \
                                "(valid ones: \"#{STRATEGIES.join('", "')}\")."
        end.html_safe
      end

      # Like htmlspecialchars with ENT_QUOTES, which writes ' as &#039;,
      # where CGI.escapeHTML writes &#39;, and ENT_SUBSTITUTE, which replaces
      # an invalid UTF-8 sequence with U+FFFD
      def escape_html(string, charset)
        string = substitute_invalid_utf8(string) if charset.casecmp?('UTF-8') || charset.casecmp?('UTF8')
        string = CGI.escapeHTML(string)

        string.include?('&#39;') ? string.gsub('&#39;', '&#039;') : string
      end

      # Replaces each invalid UTF-8 sequence with U+FFFD, reading the bytes
      # the way htmlspecialchars does, which differs from String#scrub: a
      # surrogate or a code point above U+10FFFF is one sequence, and so is a
      # lead byte with the bytes after it up to the first that could start a
      # character. A string in another encoding is left as it is.
      def substitute_invalid_utf8(string)
        return string unless [Encoding::UTF_8, Encoding::BINARY].include?(string.encoding)

        bytes = string.b
        return string if bytes.dup.force_encoding(Encoding::UTF_8).valid_encoding?

        result = +''
        position = 0

        while position < bytes.bytesize
          valid, length = next_utf8_character(bytes, position)
          result << (valid ? bytes.byteslice(position, length) : "\uFFFD".b)
          position += length
        end

        result.force_encoding(Encoding::UTF_8)
      end

      # @return [Array(Boolean, Integer)] Whether the character at position is
      #   valid UTF-8, and its length or the length of the invalid sequence
      def next_utf8_character(bytes, position)
        lead = bytes.getbyte(position)

        return [true, 1] if lead < 0x80
        return [false, 1] if lead < 0xC2 || lead > 0xF4

        length = [0xE0, 0xF0].count { |limit| lead >= limit } + 2
        trail = (1...length).map { |offset| bytes.getbyte(position + offset) }

        # A missing byte is nil
        unless trail.all? { |byte| byte&.between?(0x80, 0xBF) }
          return [false, 1 + trail.take_while { |byte| byte && !utf8_lead?(byte) }.length]
        end

        code_point = trail.inject(lead & (0xFF >> (length + 1))) do |point, byte|
          (point << 6) | (byte & 0x3F)
        end

        valid = case length
                when 3 then code_point >= 0x800 && !code_point.between?(0xD800, 0xDFFF)
                when 4 then code_point.between?(0x10000, 0x10FFFF)
                else true
                end

        [valid, length]
      end

      def utf8_lead?(byte)
        byte < 0x80 || byte.between?(0xC2, 0xF4)
      end

      def escape_html_attr(string, charset)
        # Convert encoding if needed
        if charset != 'UTF-8'
          string = convert_encoding(string, 'UTF-8', charset)
        end

        # Validate UTF-8
        unless string.valid_encoding?
          raise Error::Runtime, 'The string to escape is not a valid UTF-8 string.'
        end

        # Escape characters not safe for HTML attributes
        string = string.gsub(/[^a-zA-Z0-9,.\-_]/u) do |char|
          # The first byte, as PHP's ord() gives, so C1 controls such as U+0085,
          # whose first byte is 0xC2, are hex entities like other characters
          ord = char.getbyte(0)

          # Replace characters undefined in HTML with Unicode replacement character
          if (ord <= 0x1F && char != "\t" && char != "\n" && char != "\r") || ord.between?(0x7F, 0x9F)
            '&#xFFFD;'
          elsif char.bytesize == 1
            # Use named entities for common characters
            case ord
            when 34 then '&quot;'  # quotation mark
            when 38 then '&amp;'   # ampersand
            when 60 then '&lt;'    # less-than sign
            when 62 then '&gt;'    # greater-than sign
            else
              format('&#x%02X;', ord)
            end
          else
            # Use hex entities for multi-byte characters
            format('&#x%04X;', char.codepoints.first)
          end
        end

        # Convert back to original encoding if needed
        if charset != 'UTF-8'
          string = string.encode(charset, 'UTF-8')
        end

        string
      end

      def escape_html_attr_relaxed(string, charset)
        # Convert encoding if needed
        if charset != 'UTF-8'
          string = convert_encoding(string, 'UTF-8', charset)
        end

        # Validate UTF-8
        unless string.valid_encoding?
          raise Error::Runtime, 'The string to escape is not a valid UTF-8 string.'
        end

        # Less restrictive than html_attr - also allows :, @, [, and ]
        string = string.gsub(/[^a-zA-Z0-9,.\-_:@\[\]]/u) do |char|
          ord = char.getbyte(0)

          if (ord <= 0x1F && char != "\t" && char != "\n" && char != "\r") || ord.between?(0x7F, 0x9F)
            '&#xFFFD;'
          elsif char.bytesize == 1
            case ord
            when 34 then '&quot;'
            when 38 then '&amp;'
            when 60 then '&lt;'
            when 62 then '&gt;'
            else
              format('&#x%02X;', ord)
            end
          else
            format('&#x%04X;', char.codepoints.first)
          end
        end

        if charset != 'UTF-8'
          string = string.encode(charset, 'UTF-8')
        end

        string
      end

      def escape_js(string, charset)
        # Convert encoding if needed
        if charset != 'UTF-8'
          string = convert_encoding(string, 'UTF-8', charset)
        end

        # Validate UTF-8
        unless string.valid_encoding?
          raise Error::Runtime, 'The string to escape is not a valid UTF-8 string.'
        end

        string = string.gsub(/[^a-zA-Z0-9,._]/) do |char|
          codepoint = char.ord

          if JS_SHORT_MAP.key?(char)
            JS_SHORT_MAP[char]
          elsif codepoint < 0x10000
            format('\u%04X', codepoint)
          else
            # Split characters outside the BMP into surrogate pairs
            # https://tools.ietf.org/html/rfc2781.html#section-2.1
            u = codepoint - 0x10000
            high = 0xD800 | (u >> 10)
            low = 0xDC00 | (u & 0x3FF)

            format('\u%04X\u%04X', high, low)
          end
        end

        # Convert back to original encoding if needed
        if charset != 'UTF-8'
          string = string.encode(charset, 'UTF-8')
        end

        string
      end

      def escape_css(string, charset)
        # Convert encoding if needed
        if charset != 'UTF-8'
          string = convert_encoding(string, 'UTF-8', charset)
        end

        # Validate UTF-8
        unless string.valid_encoding?
          raise Error::Runtime, 'The string to escape is not a valid UTF-8 string.'
        end

        string = string.gsub(/[^a-zA-Z0-9]/) do |char|
          if char.bytesize == 1
            format('\\%X ', char.ord)
          else
            format('\\%X ', char.codepoints.first)
          end
        end

        # Convert back to original encoding if needed
        if charset != 'UTF-8'
          string = string.encode(charset, 'UTF-8')
        end

        string
      end

      def convert_encoding(string, to_encoding, from_encoding)
        string.encode(to_encoding, from_encoding)
      end
    end
  end
end
