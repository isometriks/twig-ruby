module Twig
  class Lexer
    TAG_COMMENT = %w[{# #}]
    TAG_BLOCK = %w[{% %}]
    TAG_VARIABLE = %w[{{ }}]
    WHITESPACE_TRIM = "-".freeze
    WHITESPACE_LINE_TRIM = "~".freeze
    WHITESPACE_LINE_CHARS = " \t\0\x0B".freeze
    INTERPOLATION = %w[#{ }]
    OPENING_BRACKET = '([{'.split(//)
    CLOSING_BRACKET = ')}]'.split(//)
    PUNCTUATION = OPENING_BRACKET + CLOSING_BRACKET + '?:.,|'.split(//)

    REGEX_LNUM = /[0-9]+(_[0-9]+)*/
    REGEX_FRAC = /\.#{REGEX_LNUM}/
    REGEX_EXPONENT = /[eE][+-]?#{REGEX_LNUM}/
    REGEX_DNUM = /#{REGEX_LNUM}(?:#{REGEX_FRAC})?/

    REGEX_NAME = /\A[a-zA-Z_][a-zA-Z0-9_]*/
    REGEX_STRING = /\A"([^#"\\]*(?:\\\\.[^#"\\]*)*)"|'([^'\\]*(?:\\\\.[^'\\]*)*)'/s
    REGEX_NUMBER = /\A(?:#{REGEX_DNUM}(?:#{REGEX_EXPONENT})?)/x

    STATE_DATA = 0
    STATE_BLOCK = 1
    STATE_VAR = 2
    STATE_STRING = 3
    STATE_INTERPOLATION = 4

    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
    end

    # @param [Twig::Source] source
    def tokenize(source)
      @source = source
      @code = source.code.tr("\r\n", "\n")
      @cursor = 0
      @lineno = 1
      @end = @code.length
      @tokens = []
      @state = STATE_DATA
      @states = []
      @brackets = []
      @position = -1
      @positions = @code.to_enum(:scan, lex_tokens_start).map { Regexp.last_match }

      while @cursor < @end
        case @state
        when STATE_DATA
          lex_data
        when STATE_BLOCK
          raise "no block parse yet"
        when STATE_VAR
          lex_var
        else
          raise "Unknown state: #{@state}"
        end
      end

      push_token(Token::EOF_TYPE)

      TokenStream.new(@tokens, @source)
    end

    private

    def lex_data
      # If no matches are left we return the rest of the template as simple text token
      if @position == @positions.length - 1
        push_token(Token::TEXT_TYPE, @code[@cursor..])

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
      text = textContent = @code[@cursor, (position.begin(0) - @cursor)]

      # TODO: Trim

      push_token(Token::TEXT_TYPE, text)
      move_cursor(textContent + position.to_s)

      case @positions[@position][1]
      when TAG_BLOCK[0]
        # @todo
      when TAG_VARIABLE[0]
        push_token(Token::VAR_START_TYPE)
        push_state(STATE_VAR)
        @current_var_block_line = @lineno
      else
        raise "Invalid start token #{@positions[@position]}"
      end
    end

    def lex_var
      match = @code[@cursor...].match(lex_var_regex)

      if @brackets.empty? && match
        push_token(Token::VAR_END_TYPE)
        move_cursor(match.to_s)
        pop_state
      else
        lex_expression
      end
    end

    def lex_expression
      @code[@cursor..].match(/\A\s+/) do |match|
        move_cursor(match.to_s)

        if @cursor >= @end
          raise "Unclosed #{@state == STATE_BLOCK ? 'block' : 'variable'}"
        end
      end

      # Spread operator
      if code_at?(0, '.') && (@cursor + 2 < @end) && code_at?(1, '.') && code_at?(2, '.')
        push_token(Token::SPREAD_TYPE)
        move_cursor('...')
      # Arrow function
      elsif code_at?(0, '=') && (@cursor + 1 < @end) && code_at?(1, '>')
        push_token(Token::ARROW_TYPE)
        move_cursor('=>')
      elsif (match = @code[@cursor..].match(operator_regex))
        push_token(Token::OPERATOR_TYPE, match.to_s.gsub('/\s+/', ' '))
        move_cursor(match.to_s)
      elsif (match = @code[@cursor..].match(REGEX_NAME))
        push_token(Token::NAME_TYPE, match.to_s)
        move_cursor(match.to_s)
      elsif (match = @code[@cursor..].match(REGEX_NUMBER))
        value = match.to_s.tr('_', '')
        value = value.to_i.to_s == value ? value.to_i : value.to_f
        push_token(Token::NUMBER_TYPE, value)
        move_cursor(match.to_s)
      elsif code_at?(0, PUNCTUATION)
        # opening bracket
        if code_at?(0, OPENING_BRACKET)
          @brackets << [code_at, @lineno]
        elsif code_at?(0, CLOSING_BRACKET)
          raise "Unexpected closing bracket: #{code_at} on #{@lineno}" if @brackets.empty?

          expect, lineno = @brackets.pop

          unless code_at?(0, expect.tr(OPENING_BRACKET.join, CLOSING_BRACKET.join))
            raise "Unclosed bracket: #{code_at} on #{lineno}"
          end
        end

        push_token(Token::PUNCTUATION_TYPE, code_at)
        @cursor += 1
      elsif (match = @code[@cursor..].match(REGEX_STRING))
        push_token(Token::STRING_TYPE, match.to_s[1...-1])
        move_cursor(match.to_s)
      end

      <<-TEMP
        // opening double quoted string
        elseif (preg_match(self::REGEX_DQ_STRING_DELIM, $this->code, $match, 0, $this->cursor)) {
            $this->brackets[] = ['"', $this->lineno];
            $this->pushState(self::STATE_STRING);
            $this->moveCursor($match[0]);
        }
        // inline comment
        elseif (preg_match(self::REGEX_INLINE_COMMENT, $this->code, $match, 0, $this->cursor)) {
            $this->moveCursor($match[0]);
        }
        // unlexable
        else {
            throw new SyntaxError(\sprintf('Unexpected character "%s".', $this->code[$this->cursor]), $this->lineno, $this->source);
        }
      TEMP
    end

    def push_token(type, value = "")
      return if type == Token::TEXT_TYPE && value.empty?

      @tokens << Token.new(type, value, @lineno)
    end

    def push_state(state)
      @states << @state
      @state = state
    end

    def pop_state
      if @states.empty?
        raise "Cannot pop state without a previous state."
      end

      @state = @states.pop
    end

    def move_cursor(text)
      @cursor += text.length
      @lineno += text.scan("\n").count
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

    def escape_and_pipe(tokens)
      tokens.
        map { |token| Regexp.escape(token) }.
        join("|")
    end

    def lex_tokens_start
      return @lex_tokens_start if defined?(@lex_tokens_start)

      lex_open = escape_and_pipe([TAG_VARIABLE[0], TAG_BLOCK[0], TAG_COMMENT[0]])
      whitespace = escape_and_pipe([WHITESPACE_TRIM, WHITESPACE_LINE_TRIM])

      @lex_tokens_start = Regexp.new("(#{lex_open})(#{whitespace})?", "xm")
    end

    def lex_var_regex
      return @lex_var_regex if defined?(@lex_var_regex)

      trim_tag = Regexp.escape(WHITESPACE_TRIM + TAG_VARIABLE[1])
      trim_line_tag = Regexp.escape(WHITESPACE_LINE_TRIM + TAG_VARIABLE[1])
      whitespace_chars = Regexp.escape(WHITESPACE_LINE_CHARS)
      tag_end = Regexp.escape(TAG_VARIABLE[1])

      @lex_var_regex = /\A\s*(?:#{trim_tag}\s*|#{trim_line_tag}[#{whitespace_chars}]*|#{tag_end})/x
    end

    def operator_regex
      return @operator_regex if defined?(@operator_regex)

      unary, binary = @environment.operators
      operators = ([:'='] + unary.keys + binary.keys).
        map { |op| [op, op.length] }.
        to_h.
        sort_by { |_, length| -length }.
        to_h

      chain = []

      operators.keys.each do |operator|
        regex = Regexp.escape(operator)

        # an operator that ends with a character must be followed by
        # a whitespace, a parenthesis, an opening map [ or sequence {
        if operator[-1].match(/\w/)
          regex << '(?=[\s()\[{])'
        end

        # an operator that begins with a character must not have a dot or pipe before
        if operator[0].match(/\w/)
          regex = '(?<![\.\|])' + regex
        end

        # an operator with a space can be any amount of whitespaces
        regex.gsub!(/\s+/, '\s+')

        chain << regex
      end

      @operator_regex = Regexp.new('\A(?:' + chain.join('|') + ')')
    end
  end
end
