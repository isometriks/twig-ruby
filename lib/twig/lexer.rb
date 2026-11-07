# frozen_string_literal: true

module Twig
  class Lexer
    TAG_COMMENT = %w[{# #}].freeze
    TAG_BLOCK = %w[{% %}].freeze
    TAG_VARIABLE = %w[{{ }}].freeze
    WHITESPACE_TRIM = '-'
    WHITESPACE_LINE_TRIM = '~'
    WHITESPACE_LINE_CHARS = " \t\0\x0B"
    INTERPOLATION = %w[#{ }].freeze
    OPENING_BRACKET = '([{'.chars
    CLOSING_BRACKET = ')]}'.chars
    PUNCTUATION = OPENING_BRACKET + CLOSING_BRACKET + '?:.,|'.chars

    REGEX_LNUM = /[0-9]+(_[0-9]+)*/
    REGEX_FRAC = /\.#{REGEX_LNUM}/
    REGEX_EXPONENT = /[eE][+-]?#{REGEX_LNUM}/
    REGEX_DNUM = /#{REGEX_LNUM}(?:#{REGEX_FRAC})?/

    # Twig's byte-based [a-zA-Z_\x7f-\xff] takes in every byte of a multibyte
    # UTF-8 character, so any character from U+007F is a name character
    REGEX_NAME = /[a-zA-Z_\u{007f}-\u{10ffff}][a-zA-Z0-9_\u{007f}-\u{10ffff}]*/u
    REGEX_SYMBOL = /:#{REGEX_NAME}/
    REGEX_CVAR = /@#{REGEX_NAME}/
    REGEX_STRING = /\G(?:"([^#"\\]*(?:\\.[^#"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)')/mu
    REGEX_DQ_STRING_PART = /\G[^#"\\]*(?:(?:\\.|#(?!\{))[^#"\\]*)*/mu
    REGEX_INLINE_COMMENT = /\G#[^\r\n]*/
    REGEX_DQ_STRING_DELIM = /\G"/
    REGEX_INTERP_START = /\G#\{[[:space:]]*/
    REGEX_INTERP_END = /\G[[:space:]]*\}/
    REGEX_NUMBER = /\G(?:#{REGEX_DNUM}(?:#{REGEX_EXPONENT})?)/x

    STATE_DATA = 0
    STATE_BLOCK = 1
    STATE_VAR = 2
    STATE_STRING = 3
    STATE_INTERPOLATION = 4

    SPECIAL_CHARS = {
      'f' => "\f",
      'n' => "\n",
      'r' => "\r",
      't' => "\t",
      'v' => "\v",
    }.freeze

    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
    end

    # @param [Twig::Source] source
    def tokenize(source)
      @source = source
      @code = source.code
      @cursor = 0
      @lineno = 1
      @end = @code.length
      @tokens = []
      @state = STATE_DATA
      @states = []
      @brackets = []
      @unclaimed_colons = {}
      @ternaries = [0]
      @ternaries_counted = 0
      @position = -1
      @positions = @code.to_enum(:scan, lex_tokens_start).map { Regexp.last_match }

      while @cursor < @end
        case @state
        when STATE_DATA
          lex_data
        when STATE_BLOCK
          lex_block
        when STATE_VAR
          lex_var
        when STATE_STRING
          lex_string
        when STATE_INTERPOLATION
          lex_interpolation
        else
          raise "Unknown state: #{@state}"
        end
      end

      push_token(Token::EOF_TYPE)

      unless @brackets.empty?
        expect, lineno = @brackets.pop

        raise Error::Syntax.new("Unclosed \"#{expect}\".", lineno, @source)
      end

      TokenStream.new(@tokens, @source)
    end

    private

    def lex_data
      # If no matches are left we return the rest of the template as simple text token
      if @position == @positions.length - 1
        text = @code[@cursor..]
        push_token(Token::TEXT_TYPE, normalize_newlines(text))
        move_cursor(text)

        return
      end

      # Find the first token after the current cursor
      @position += 1
      position = @positions[@position]

      while position.begin(0) < @cursor
        return if @position == @positions.length - 1

        @position += 1
        position = @positions[@position]
      end

      # Push the template text first
      text = text_content = @code[@cursor, (position.begin(0) - @cursor)]

      # trim?
      char = @positions[@position][2]

      if char == WHITESPACE_TRIM
        text = text.rstrip
      elsif char == WHITESPACE_LINE_TRIM
        text = text.gsub(/[ \t\0\x0B]*\z/, '')
      end

      push_token(Token::TEXT_TYPE, normalize_newlines(text))
      move_cursor(text_content)

      case @positions[@position][1]
      when TAG_COMMENT[0]
        move_cursor(position.to_s)
        lex_comment
      when TAG_BLOCK[0]
        lineno = @lineno
        cursor = @cursor
        move_cursor(position.to_s)

        if (match = @code.match(lex_block_raw_regex, @cursor))
          move_cursor(match.to_s)
          lex_raw_data
        elsif (match = @code.match(lex_block_line_regex, @cursor))
          move_cursor(match[0].to_s)
          @lineno = match[1].to_i
        else
          push_token(Token::BLOCK_START_TYPE, '', cursor, lineno)
          push_state(STATE_BLOCK)
          @current_var_block_line = @lineno
        end
      when TAG_VARIABLE[0]
        lineno = @lineno
        cursor = @cursor
        move_cursor(position.to_s)
        push_token(Token::VAR_START_TYPE, '', cursor, lineno)
        push_state(STATE_VAR)
        @current_var_block_line = @lineno
      else
        raise Error::Syntax.new("Invalid start token #{@positions[@position]}", @lineno)
      end
    end

    def lex_raw_data
      unless (match = @code.match(lex_raw_data_regex, @cursor))
        raise Error::Syntax.new('Unexpected end of file: Unclosed "verbatim" block.', @lineno, @source)
      end

      offset = @cursor
      text = @code[@cursor, match.begin(0) - @cursor]
      move_cursor(@code[@cursor, (text.length + match.to_s.length)])

      # trim
      if match[1]
        text = if match[1] == WHITESPACE_TRIM
                 text.rstrip # line trim
               else
                 text.gsub(/[ \t\0\x0B]*\z/, '') # space trim
               end
      end

      push_token(Token::TEXT_TYPE, normalize_newlines(text), offset)
    end

    def lex_block
      if @brackets.empty? && (match = @code.match(lex_block_regex, @cursor))
        push_closing_token(Token::BLOCK_END_TYPE, match.to_s)
        pop_state
      else
        lex_expression
      end
    end

    def lex_var
      match = @code.match(lex_var_regex, @cursor)

      if @brackets.empty? && match
        push_closing_token(Token::VAR_END_TYPE, match.to_s)
        pop_state
      else
        lex_expression
      end
    end

    def lex_expression
      @code.match(/\G[[:space:]]+/, @cursor) do |match|
        move_cursor(match.to_s)

        if @cursor >= @end
          raise Error::Syntax.new(
            "Unclosed \"#{@state == STATE_BLOCK ? 'block' : 'variable'}\".",
            @current_var_block_line,
            @source
          )
        end
      end

      if (match = @code.match(operator_regex, @cursor))
        operator = match.to_s.gsub(/[[:space:]]+/, ' ')

        # a ? :x : :y is a ternary with a symbol, not the ? : alias of ?:
        if operator == '? :' && symbol_ternary?(match.end(0))
          push_token(Token::OPERATOR_TYPE, '?')
          move_cursor('?')

          return
        end

        if OPENING_BRACKET.include?(operator)
          check_brackets(operator)
        end

        push_token(Token::OPERATOR_TYPE, operator)
        move_cursor(match.to_s)
      elsif (match = @code.match(/\G#{REGEX_NAME}/, @cursor))
        name = match.to_s
        name += '?' if predicate_mark?(@cursor + name.length)

        push_token(Token::NAME_TYPE, name)
        move_cursor(name)

        # x? :a : :b is a ternary with a symbol, not the ? : alias of ?:
        if @code.match?(/\G\?[[:space:]]+#{REGEX_SYMBOL}/, @cursor)
          push_token(Token::OPERATOR_TYPE, '?')
          move_cursor('?')
        end
      elsif (match = @code.match(/\G#{REGEX_SYMBOL}/, @cursor))
        push_token(Token::SYMBOL_TYPE, match.to_s[1..])
        move_cursor(match.to_s)
      elsif (match = @code.match(/\G#{REGEX_CVAR}/, @cursor))
        push_token(Token::CLASS_VAR_TYPE, match.to_s)
        move_cursor(match.to_s)
      elsif (match = @code.match(REGEX_NUMBER, @cursor))
        # digits alone are a decimal integer, even with leading zeros (010 is
        # 10), as PHP's 0 + '010' gives; a fraction or an exponent is a float,
        # and so is an integer too big for PHP
        value = match.to_s.tr('_', '')
        value = value.match?(/\A[0-9]+\z/) && value.to_i <= Runtime::Arithmetic::INT_MAX ? value.to_i : value.to_f
        push_token(Token::NUMBER_TYPE, value)
        move_cursor(match.to_s)
      elsif code_at?(0, PUNCTUATION)
        check_brackets(code_at)
        push_token(Token::PUNCTUATION_TYPE, code_at)
        move_cursor(code_at)
      elsif (match = @code.match(REGEX_STRING, @cursor))
        push_token(Token::STRING_TYPE, stripcslashes(normalize_newlines(match.to_s[1...-1]), match.to_s[0]))
        move_cursor(match.to_s)
      elsif (match = @code.match(REGEX_DQ_STRING_DELIM, @cursor))
        @brackets << ['"', @lineno]
        push_state(STATE_STRING)
        move_cursor(match.to_s)
      elsif (match = @code.match(REGEX_INLINE_COMMENT, @cursor))
        move_cursor(match.to_s)
      else
        raise_unexpected_character
      end
    end

    # Whether the ? at position belongs to the name before it, like a Ruby
    # predicate (user_signed_in?), rather than starting a ternary (a?b:c).
    #
    # The ? is part of the name only when a ternary couldn't follow: before a
    # call's parenthesis, or when what comes next (after any whitespace)
    # can't start an expression, such as the end of the tag, a closing bracket,
    # a comma, a filter or a binary operator. Anything that could start an
    # expression leaves the ? to the ternary, as in Twig PHP. A mapping key
    # keeps it before its colon ({visible?: true}), and an attribute keeps it
    # before an operator that could also go on with the expression
    # (user.admin? - 1, user.roles?[0]), as it always has.
    #
    # @param [Integer] position
    # @param [Boolean] attribute whether the name is an attribute (after a .)
    # @param [Boolean] key whether the name is a key of the mapping it's in
    def predicate_mark?(position, attribute: @tokens.last&.test(Token::OPERATOR_TYPE, '.'), key: mapping_key?)
      return false unless @code[position] == '?'

      after = position + 1

      # a?(x) calls a?
      return true if @code[after] == '('

      # {visible?: true} is a key followed by its colon, not a?:b
      return true if @code[after] == ':' && key

      # a??b, a?:b and the like are operators that start with ?
      operator = @code.match(operator_regex, position)&.to_s
      return false if operator && operator != '?' && !operator.match?(/[[:space:]]/)

      return true if @code.match?(lex_var_regex, after) || @code.match?(lex_block_regex, after)

      rest = @code.match(/\G[[:space:]]*/, after).end(0)

      return true if rest >= @end

      case @code[rest]
      when ')', ']', '}', ',', '|', '?', '.', '#'
        true
      when ':'
        # :name is a symbol, which starts an expression
        !@code.match?(/\G#{REGEX_SYMBOL}/, rest)
      else
        # a binary operator can't start an expression, but a unary one can
        operator = @code.match(operator_regex, rest)&.to_s&.gsub(/[[:space:]]+/, ' ')
        return false if operator.nil?
        return true unless expression_start_operators.include?(operator)

        # user.admin? - 1 and user.roles?[0] go on with the attribute
        attribute && infix_operators.include?(operator)
      end
    end

    # Whether the : at position - 1, after a spaced ?, starts a symbol that is
    # the first branch of a ternary, as in a ? :x : :y. It does when the
    # expression after the symbol has a : left over once the ternaries still
    # open before the ? have taken theirs. Without one, a ? :x stays a ?: x,
    # as in Twig PHP, and so does c ? a ? :x : z, which reads
    # c ? (a ?: x) : z.
    #
    # @param [Integer] position
    def symbol_ternary?(position)
      name = @code.match(/\G#{REGEX_NAME}/, position)
      return false unless name

      unclaimed_colons(name.end(0)) > open_ternaries
    end

    # The ternaries of the expression being lexed, outside brackets, that are
    # still waiting for their :. Only the tokens pushed since the last call
    # are counted, with a count for each bracket still open, so each token is
    # counted once.
    def open_ternaries
      while @ternaries_counted < @tokens.length
        count_ternaries(@tokens[@ternaries_counted])
        @ternaries_counted += 1
      end

      @ternaries.last
    end

    # @param [Token] token
    def count_ternaries(token)
      case token.type
      when Token::VAR_START_TYPE, Token::BLOCK_START_TYPE
        @ternaries = [0]
      when Token::INTERPOLATION_START_TYPE
        @ternaries << 0
      when Token::INTERPOLATION_END_TYPE
        @ternaries.pop if @ternaries.length > 1
      when Token::OPERATOR_TYPE, Token::PUNCTUATION_TYPE
        case token.value
        when *OPENING_BRACKET
          @ternaries << 0
        when *CLOSING_BRACKET
          @ternaries.pop if @ternaries.length > 1
        when ','
          @ternaries[-1] = 0
        when '?'
          @ternaries[-1] += 1
        when ':'
          @ternaries[-1] -= 1 if @ternaries.last.positive?
        end
      end
    end

    # The number of : in the expression after position, outside brackets,
    # that close no ternary started after position, up to a comma, a closing
    # bracket or the end of the tag. A later ? : with a symbol counts as a
    # ternary: when it is the alias of ?: instead, it is because it has no :
    # over, so it has none to leave to the ? : before it either. The count is
    # kept by position, so a chain of ? : is scanned once.
    #
    # @param [Integer] position
    # @return [Integer]
    def unclaimed_colons(position)
      @unclaimed_colons[position] ||= count_unclaimed_colons(position)
    end

    # @param [Integer] position
    # @return [Integer]
    def count_unclaimed_colons(position)
      depth = 0
      # the ternaries after position still waiting for their :
      ternaries = 0
      unclaimed = 0

      while position < @end
        break if depth.zero? && (@code.match?(lex_var_regex, position) || @code.match?(lex_block_regex, position))

        char = @code[position]

        case char
        when '"', "'"
          position = skip_string(position)
          next
        when '#'
          position = @code.match(REGEX_INLINE_COMMENT, position).end(0)
          next
        when *OPENING_BRACKET
          depth += 1
        when *CLOSING_BRACKET, ','
          break if depth.zero?

          depth -= 1 unless char == ','
        when ':'
          # :name is another symbol
          if depth.zero? && !@code.match?(/\G#{REGEX_NAME}/, position + 1)
            ternaries.zero? ? unclaimed += 1 : ternaries -= 1
          end
        else
          if (name = @code.match(/\G#{REGEX_NAME}/, position))
            position = name.end(0)
            next unless @code[position] == '?'

            if predicate_mark?(position, attribute: attribute_name?(name.begin(0)), key: false)
              # b? is a predicate, its ? no ternary
              position += 1
            elsif depth.zero? && @code.match?(/\G\?[[:space:]]+#{REGEX_SYMBOL}/, position)
              # b? :c : :d is a ternary with a symbol
              ternaries += 1
              position += 1
            end

            next
          end

          if (operator = @code.match(operator_regex, position))
            spaced = operator.to_s.gsub(/[[:space:]]+/, ' ')

            if depth.zero? && spaced == '?'
              ternaries += 1
            elsif depth.zero? && spaced == '? :' && (name = @code.match(/\G#{REGEX_NAME}/, operator.end(0)))
              # b ? :c waits for a : too, and the rest after :c has its own
              # count
              return unclaimed + [unclaimed_colons(name.end(0)) - ternaries - 1, 0].max
            end

            # ?: and ? : are operators, not the ? of a ternary
            position = operator.end(0)
            next
          end
        end

        position += 1
      end

      unclaimed
    end

    # Whether the name that starts at position comes after a ., as an
    # attribute does.
    #
    # @param [Integer] position
    def attribute_name?(position)
      position -= 1
      position -= 1 while position >= 0 && @code[position].match?(/[[:space:]]/)

      position >= 0 && @code[position] == '.'
    end

    # Returns the position after the string literal that starts at position,
    # with any interpolations in it.
    #
    # @param [Integer] position
    def skip_string(position)
      quote = @code[position]
      position += 1

      while position < @end
        case @code[position]
        when '\\'
          position += 1
        when quote
          return position + 1
        when '#'
          position = skip_interpolation(position + 2) if quote == '"' && @code[position + 1] == '{'
        end

        position += 1
      end

      position
    end

    # Returns the position of the } that closes the interpolation whose code
    # starts at position.
    #
    # @param [Integer] position
    def skip_interpolation(position)
      depth = 0

      while position < @end
        case @code[position]
        when '"', "'"
          position = skip_string(position)
          next
        when '{'
          depth += 1
        when '}'
          return position if depth.zero?

          depth -= 1
        end

        position += 1
      end

      position
    end

    # Whether the name being lexed is a key of the mapping it's directly in.
    def mapping_key?
      @brackets.last&.first == '{' && @tokens.last&.test(Token::PUNCTUATION_TYPE, ['{', ','])
    end

    # Operators that can go on with an expression, such as - and [.
    def infix_operators
      @infix_operators ||= [].tap do |operators|
        environment.expression_parsers.each do |parser|
          operators.push(*parser.operator_tokens) if parser.type == :infix
        end
      end
    end

    # Operators that can begin an expression: the prefix (unary) operators,
    # and [ for a sequence.
    def expression_start_operators
      @expression_start_operators ||= ['['].tap do |operators|
        environment.expression_parsers.each do |parser|
          operators.push(*parser.operator_tokens) if parser.type == :prefix
        end
      end
    end

    def lex_comment
      unless (match = @code.match(lex_comment_regex, @cursor))
        raise Error::Syntax.new('Unclosed comment.', @lineno, @source)
      end

      move_cursor(@code[@cursor...match.offset(0)[1]])
    end

    def lex_string
      if (match = @code.match(REGEX_INTERP_START, @cursor))
        @brackets << ['#{', @lineno]
        push_token(Token::INTERPOLATION_START_TYPE)
        move_cursor(match.to_s)
        push_state(STATE_INTERPOLATION)
      elsif (match = @code.match(REGEX_DQ_STRING_PART, @cursor)) && match.to_s != ''
        push_token(Token::STRING_TYPE, stripcslashes(normalize_newlines(match.to_s), '"'))
        move_cursor(match.to_s)
      elsif @code.match(REGEX_DQ_STRING_DELIM, @cursor)
        expect, lineno = @brackets.pop

        unless code_at?(0, '"')
          raise Error::Syntax.new("Unclosed \"#{expect}\".", lineno, @source)
        end

        pop_state
        move_cursor('"')
      else
        raise_unexpected_character
      end
    end

    def raise_unexpected_character
      raise Error::Syntax.new(
        "Unexpected character \"#{code_at}\".",
        @lineno,
        @source,
        column: @source.column(@cursor)
      )
    end

    # Unescapes a string literal as Twig does. A \x or octal escape gives a
    # byte, which may be part of a multibyte character ("\xc3\xa9" is é), so
    # the result is built as bytes and then given the encoding of str.
    #
    # @return [String]
    def stripcslashes(str, quote_type)
      result = String.new(encoding: Encoding::BINARY)
      length = str.length

      i = 0
      while i < length
        pos = str.index('\\', i)

        unless pos
          result << str[i..].b
          break
        end

        result << str[i...pos].b
        i = pos + 1

        if i >= length
          result << '\\'
          break
        end

        next_char = str[i]

        if SPECIAL_CHARS.key?(next_char)
          result << SPECIAL_CHARS[next_char]
        elsif next_char == '\\' || next_char == quote_type
          result << next_char
        elsif next_char == '#' && i + 1 < length && str[i + 1] == '{'
          result << '#{'
          i += 1
        elsif next_char == 'x' && i + 1 < length && str[i + 1].match?(/[0-9a-fA-F]/)
          hex = str[i + 1]
          i += 1
          if i + 1 < length && str[i + 1].match?(/[0-9a-fA-F]/)
            hex += str[i + 1]
            i += 1
          end
          result << hex.to_i(16)
        elsif next_char.match?(/[0-7]/) # octal
          octal = next_char
          while i + 1 < length && str[i + 1].match?(/[0-7]/) && octal.length < 3
            octal += str[i + 1]
            i += 1
          end
          result << (octal.to_i(8) % 256)
        else
          result << "\\#{next_char}".b
        end

        i += 1
      end

      result.force_encoding(str.encoding)
    end

    # A token starts at the cursor unless the caller passes the offset (and
    # line) of a token it already moved past.
    def push_token(type, value = '', offset = nil, lineno = nil)
      return if type == Token::TEXT_TYPE && value.empty?

      @tokens << Token.new(type, value, lineno || @lineno, offset || @cursor)
    end

    # Pushes a closing delimiter token at the delimiter itself, not at the
    # whitespace its regex matched before it.
    def push_closing_token(type, match)
      leading_whitespace = match.length - match.lstrip.length
      move_cursor(match[0, leading_whitespace]) if leading_whitespace.positive?

      push_token(type)
      move_cursor(match[leading_whitespace..])
    end

    def lex_interpolation
      bracket = @brackets.last
      if bracket[0] == '#{' && (match = @code.match(REGEX_INTERP_END, @cursor))
        @brackets.pop
        push_closing_token(Token::INTERPOLATION_END_TYPE, match.to_s)
        pop_state
      else
        lex_expression
      end
    end

    def push_state(state)
      @states << @state
      @state = state
    end

    def pop_state
      if @states.empty?
        raise 'Cannot pop state without a previous state.'
      end

      @state = @states.pop
    end

    # The cursor is a character offset into the original code, which keeps
    # its line endings, so "\r\n" and "\r" each count as one line.
    def move_cursor(text)
      @cursor += text.length
      @lineno += (text.include?("\r") ? normalize_newlines(text) : text).count("\n")
    end

    # @param [String] text
    # @return [String]
    def normalize_newlines(text)
      text.gsub(/\r\n?/, "\n")
    end

    # @param [Integer] seek
    # @return [String]
    def code_at(seek = 0)
      @code[@cursor + seek]
    end

    # @param [Integer] seek
    # @param [String | Array] char
    def code_at?(seek, char)
      dest = code_at(seek)

      case char
      when Array
        char.include?(dest)
      when String
        dest == char
      else
        raise "Invalid char: #{char.inspect}"
      end
    end

    def lex_tokens_start
      @lex_tokens_start ||=
        /
          (#{Regexp.union([TAG_VARIABLE[0], TAG_BLOCK[0], TAG_COMMENT[0]])})
          (#{Regexp.union([WHITESPACE_TRIM, WHITESPACE_LINE_TRIM])})?
        /xm
    end

    def lex_var_regex
      @lex_var_regex ||=
        /\G[[:space:]]*(?:
          #{Regexp.union(
            /#{WHITESPACE_TRIM}#{TAG_VARIABLE[1]}[[:space:]]*/,
            /#{WHITESPACE_LINE_TRIM}#{TAG_VARIABLE[1]}[#{WHITESPACE_LINE_CHARS}]*/,
            TAG_VARIABLE[1]
          )}
        )/x
    end

    def lex_comment_regex
      @lex_comment_regex ||=
        /
          (?:#{Regexp.union(
            /#{WHITESPACE_TRIM}#{TAG_COMMENT[1]}[[:space:]]*\n?/,
            /#{WHITESPACE_LINE_TRIM}#{TAG_COMMENT[1]}[#{WHITESPACE_LINE_CHARS}]*/,
            /#{TAG_COMMENT[1]}(?:\r\n?|\n)?/
          )})
        /mxu
    end

    def lex_block_raw_regex
      @lex_block_raw_regex ||=
        /\G[[:space:]]*verbatim[[:space:]]*(?:
          #{Regexp.union(
            /#{WHITESPACE_TRIM}#{TAG_BLOCK[1]}[[:space:]]*/,
            /#{WHITESPACE_LINE_TRIM}#{TAG_BLOCK[1]}[#{WHITESPACE_LINE_CHARS}]*/,
            TAG_BLOCK[1]
          )}
        )/mxu
    end

    def lex_block_line_regex
      @lex_block_line_regex ||= /\G[[:space:]]*line[[:space:]]+(\d+)[[:space:]]*#{Regexp.escape(TAG_BLOCK[1])}/mu
    end

    def lex_block_regex
      @lex_block_regex ||=
        /\G[[:space:]]*(?:
          #{Regexp.union(
            /#{WHITESPACE_TRIM}#{TAG_BLOCK[1]}[[:space:]]*\n?/,
            /#{WHITESPACE_LINE_TRIM}#{TAG_BLOCK[1]}[#{WHITESPACE_LINE_CHARS}]*/,
            /#{TAG_BLOCK[1]}(?:\r\n?|\n)?/
          )}
        )/x
    end

    def lex_raw_data_regex
      @lex_raw_data_regex ||=
        /
          #{TAG_BLOCK[0]}
          (#{Regexp.union(WHITESPACE_TRIM, WHITESPACE_LINE_TRIM)})?[[:space:]]*endverbatim[[:space:]]*
          (?:#{Regexp.union(
            /#{WHITESPACE_TRIM}#{TAG_BLOCK[1]}[[:space:]]*/,
            /#{WHITESPACE_LINE_TRIM}#{TAG_BLOCK[1]}[#{WHITESPACE_LINE_CHARS}]*/,
            TAG_BLOCK[1]
          )})
        /xu
    end

    def operator_regex
      return @operator_regex if defined?(@operator_regex)

      expression_parsers = []

      environment.expression_parsers.each do |expression_parser|
        expression_parsers.concat(expression_parser.operator_tokens)
      end

      operators = expression_parsers.
        to_h { |op| [op, op.length] }.
        sort_by { |_, length| -length }.
        to_h

      chain = []

      operators.each_key do |operator|
        regex = Regexp.escape(operator)

        # an operator that ends with a character must be followed by
        # a whitespace, a parenthesis, an opening map [ or sequence {
        if operator[-1].match(/\w/)
          regex << '(?=[[[:space:]]()\[{])'
        end

        # an operator that begins with a character must not have a dot or
        # pipe before, even with a whitespace in between ('foo' | and)
        if operator[0].match(/\w/)
          regex = "(?<![\\.\\|]|[\\.\\|][[:space:]])#{regex}"
        end

        # an operator with a space can be any amount of whitespaces
        regex.gsub!(/(\\\s)+/, '[[:space:]]+')

        chain << regex
      end

      @operator_regex = Regexp.new("\\G(?:#{chain.join('|')})")
    end

    # @param [String]
    def check_brackets(code)
      if OPENING_BRACKET.include?(code)
        @brackets << [code, @lineno]
      elsif CLOSING_BRACKET.include?(code)
        if @brackets.empty?
          raise Error::Syntax.new("Unexpected \"#{code}\".", @lineno, @source, column: @source.column(@cursor))
        end

        expect, lineno = @brackets.pop

        unless code_at?(0, expect.tr(OPENING_BRACKET.join, CLOSING_BRACKET.join))
          raise Error::Syntax.new("Unclosed \"#{expect}\".", lineno, @source)
        end
      end
    end

    # @return [Environment]
    attr_reader :environment
  end
end
