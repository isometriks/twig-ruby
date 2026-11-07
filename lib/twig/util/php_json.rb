# frozen_string_literal: true

module Twig
  module Util
    # Writes JSON the way PHP's json_encode does from what to_json gives:
    # strings are escaped as PHP escapes them, which by default writes / as
    # \/ and a character outside ASCII as \u escapes, and the flags of
    # json_encode that change the escaping or pretty print are applied.
    module PhpJson
      HEX_TAG = 1
      HEX_AMP = 2
      HEX_APOS = 4
      HEX_QUOT = 8
      UNESCAPED_SLASHES = 64
      PRETTY_PRINT = 128
      UNESCAPED_UNICODE = 256
      UNESCAPED_LINE_TERMINATORS = 2048

      STRING = /"(?:[^"\\]|\\.)*"/m
      SHORT_ESCAPES = { "\b" => '\b', "\f" => '\f', "\n" => '\n', "\r" => '\r', "\t" => '\t' }.freeze
      HEX_ESCAPES = { '<' => HEX_TAG, '>' => HEX_TAG, '&' => HEX_AMP, "'" => HEX_APOS, '"' => HEX_QUOT }.freeze

      module_function

      # @param [Object] object
      # @param [Integer] flags
      # @return [String, false] false when the value can't be encoded, such
      #   as a string that isn't valid UTF-8 or NaN, as in PHP
      def encode(object, flags = 0)
        json = object.respond_to?(:to_json) ? object.to_json : '{}'
        json = json.gsub(STRING) { |string| escape(JSON.parse(string), flags) }

        flags.allbits?(PRETTY_PRINT) ? pretty(json) : json
      rescue JSON::GeneratorError, EncodingError
        false
      end

      # @param [String] string
      # @param [Integer] flags
      def escape(string, flags)
        escaped = string.each_char.map do |char|
          if (flag = HEX_ESCAPES[char]) && flags.allbits?(flag)
            format('\u%04X', char.ord)
          else
            escape_char(char, flags)
          end
        end

        "\"#{escaped.join}\""
      end

      def escape_char(char, flags)
        code_point = char.ord

        case char
        when '"' then '\"'
        when '\\' then '\\\\'
        when '/' then flags.nobits?(UNESCAPED_SLASHES) ? '\/' : '/'
        else
          if SHORT_ESCAPES.key?(char)
            SHORT_ESCAPES[char]
          elsif code_point < 0x20
            format('\u%04x', code_point)
          elsif code_point < 0x80 || (flags.allbits?(UNESCAPED_UNICODE) && !line_terminator?(code_point, flags))
            char
          else
            char.encode('UTF-16BE').unpack('n*').map { |unit| format('\u%04x', unit) }.join
          end
        end
      end

      # U+2028 and U+2029 stay escaped with JSON_UNESCAPED_UNICODE, unless
      # JSON_UNESCAPED_LINE_TERMINATORS is given too
      def line_terminator?(code_point, flags)
        [0x2028, 0x2029].include?(code_point) && flags.nobits?(UNESCAPED_LINE_TERMINATORS)
      end

      # PHP's pretty print: four spaces, "key": value, and [] and {} for an
      # empty sequence or mapping
      def pretty(json)
        depth = 0

        json.gsub(/#{STRING}|[\[{]\s*[\]}]|[\[{\]},:]/o) do |token|
          case token
          when '[', '{' then "#{token}\n#{'    ' * (depth += 1)}"
          when ']', '}' then "\n#{'    ' * (depth -= 1)}#{token}"
          when ',' then ",\n#{'    ' * depth}"
          when ':' then ': '
          else token
          end
        end
      end
    end
  end
end
