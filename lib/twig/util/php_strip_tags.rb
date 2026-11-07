# frozen_string_literal: true

module Twig
  module Util
    # A port of PHP's strip_tags (php_strip_tags_ex), which removes tags,
    # comments and processing instructions byte by byte and leaves the text
    # between them as it is, where an HTML parser would decode entities and
    # put whitespace in place of block elements.
    class PhpStripTags
      LT = '<'.ord
      GT = '>'.ord
      DOUBLE_QUOTE = '"'.ord
      SINGLE_QUOTE = "'".ord
      BACKSLASH = '\\'.ord
      SLASH = '/'.ord
      DASH = '-'.ord
      BANG = '!'.ord
      QUESTION = '?'.ord
      OPEN_PAREN = '('.ord
      CLOSE_PAREN = ')'.ord
      # What C's isspace matches
      SPACES = [0x20, 0x09, 0x0A, 0x0B, 0x0C, 0x0D].freeze

      # @param [String] string
      # @param [String, Array, nil] allowed The tags to keep, as "<a><b>" or
      #   as names
      # @return [String]
      def self.call(string, allowed = nil)
        allowed = allowed.map { |tag| "<#{tag}>" }.join if allowed.is_a?(Array)

        new(string, allowed&.to_s).call
      end

      def initialize(string, allowed)
        @buffer = string.b
        @encoding = string.encoding
        @allowed = allowed&.b&.downcase
      end

      def call
        @output = +''.b
        @tag = +''.b
        @state = 0
        @depth = 0
        @quote = nil
        @last = nil
        @brackets = 0
        @xml = false

        @buffer.each_byte.with_index do |char, position|
          @char = char
          @position = position

          case @state
          when 0 then text
          when 1 then tag
          when 2 then processing_instruction
          when 3 then declaration
          else comment
          end
        end

        @output.force_encoding(@encoding)
      end

      private

      # The byte at an offset from the current one, or 0 past either end, as
      # PHP reads a NUL-terminated buffer
      def at(offset)
        index = @position + offset

        index.negative? ? 0 : @buffer.getbyte(index) || 0
      end

      def text
        case @char
        when 0
          nil
        when LT
          return if @quote

          if SPACES.include?(at(1))
            @output << @char
          else
            @last = LT
            @state = 1
            @tag << LT if @allowed
          end
        when GT
          if @depth.positive?
            @depth -= 1
          elsif !@quote
            @output << @char
          end
        else
          @output << @char
        end
      end

      def tag
        case @char
        when 0
          nil
        when LT
          return if @quote
          return add_to_tag if SPACES.include?(at(1))

          @depth += 1
        when GT
          close_tag
        when DOUBLE_QUOTE, SINGLE_QUOTE
          toggle_quote if @position != 0
          add_to_tag
        when BANG
          return add_to_tag unless at(-1) == LT

          @state = 3
          @last = @char
        when QUESTION
          return add_to_tag unless at(-1) == LT

          @brackets = 0
          @state = 2
        else
          add_to_tag
        end
      end

      def close_tag
        return @depth -= 1 if @depth.positive?
        return if @quote

        @last = GT
        return if @xml && at(-1) == DASH

        @quote = nil
        @state = 0
        @xml = false
        return unless @allowed

        @tag << GT
        @output << @tag if allowed?(@tag)
        @tag = +''.b
      end

      def processing_instruction
        case @char
        when OPEN_PAREN, CLOSE_PAREN
          unless [DOUBLE_QUOTE, SINGLE_QUOTE].include?(@last)
            @last = @char
            @brackets += @char == OPEN_PAREN ? 1 : -1
          end
        when GT
          if @depth.positive?
            @depth -= 1
          elsif !@quote && @brackets.zero? && @last != DOUBLE_QUOTE && at(-1) == QUESTION
            back_to_text
          end
        when DOUBLE_QUOTE, SINGLE_QUOTE
          return if at(-1) == BACKSLASH

          if @last == @char
            @last = 0
          elsif @last != BACKSLASH
            @last = @char
          end

          toggle_quote if @position != 0
        when 'l'.ord, 'L'.ord
          # <?xml is a tag rather than a processing instruction
          if @position > 4 && at(-1).chr.casecmp?('m') && at(-2).chr.casecmp?('x') &&
             at(-3) == QUESTION && at(-4) == LT
            @state = 1
            @xml = true
          end
        end
      end

      def declaration
        case @char
        when GT
          if @depth.positive?
            @depth -= 1
          elsif !@quote
            back_to_text
          end
        when DOUBLE_QUOTE, SINGLE_QUOTE
          toggle_quote if @position != 0 && at(-1) != BACKSLASH
        when DASH
          @state = 4 if @position >= 2 && at(-1) == DASH && at(-2) == BANG
        when 'e'.ord, 'E'.ord
          # <!DOCTYPE is a tag
          if @position > 6 && (1..6).map { |offset| at(-offset).chr }.reverse.join.casecmp?('doctyp')
            @state = 1
          end
        end
      end

      def comment
        return unless @char == GT && !@quote && @position >= 2 && at(-1) == DASH && at(-2) == DASH

        back_to_text
      end

      def back_to_text
        @quote = nil
        @state = 0
        @tag = +''.b
      end

      def toggle_quote
        return if @quote && @quote != @char

        @quote = @quote ? nil : @char
      end

      def add_to_tag
        @tag << @char if @allowed
      end

      # Whether the tag, as <name> with any attributes and a / dropped, is one
      # of the allowed ones (php_tag_find)
      def allowed?(tag)
        tag = tag.downcase
        normalized = +''.b
        started = false

        tag.each_byte.with_index do |char, index|
          break if char == GT

          if char == LT
            normalized << char
          elsif SPACES.include?(char)
            break if started
          else
            started = true
            normalized << char unless char == SLASH && (tag.getbyte(index - 1) == LT || tag.getbyte(index + 1) == GT)
          end
        end

        @allowed.include?(normalized << GT)
      end
    end
  end
end
