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

      def escape(string, strategy = :html, charset = nil, autoescape = false)
        # Allow strings marked as html_safe to get through without escaping
        if string.html_safe? && autoescape
          return string
        end

        case strategy.to_sym
        when :html
          CGI.escapeHTML(string.to_s)
        when :html_attr
          escape_html_attr(string.to_s, charset || @charset)
        when :html_attr_relaxed
          escape_html_attr_relaxed(string.to_s, charset || @charset)
        when :js
          escape_js(string.to_s, charset || @charset)
        when :css
          escape_css(string.to_s, charset || @charset)
        when :url
          CGI.escape(string.to_s)
        else
          string.to_s
        end.html_safe
      end

      private

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
          ord = char.ord

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
          ord = char.ord

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
