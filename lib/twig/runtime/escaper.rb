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
        if string.html_safe? && %i[html html_attr].include?(strategy)
          return string
        end

        case strategy.to_sym
        when :html
          CGI.escapeHTML(string.to_s)
        when :js
          string.gsub(/[^a-zA-Z0-9,._]/) do |char|
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

              format('\u%04X\u%04X', high, low) # rubocop:disable  Style/FormatStringToken
            end
          end
        else
          string
        end
      end
    end
  end
end
