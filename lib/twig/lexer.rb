module Twig
  class Lexer
    TAG_COMMENT = %w[{# #}]
    TAG_BLOCK = %w[{% %}]
    TAG_VARIABLE = %w[{{ }}]
    WHITESPACE_TRIM = "-".freeze
    WHITESPACE_LINE_TRIM = "~".freeze
    WHITESPACE_LINE_CHARS = " \t\0\x0B".freeze
    INTERPOLATION = %w[#{ }]

    REGEX_NAME = /\A[a-zA-Z_][a-zA-Z0-9_]*/

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
      end

      <<-TEMP
        // operators
        elseif (preg_match($this->regexes['operator'], $this->code, $match, 0, $this->cursor)) {
            $this->pushToken(Token::OPERATOR_TYPE, preg_replace('/\s+/', ' ', $match[0]));
            $this->moveCursor($match[0]);
        }
        // names
        elseif (preg_match(self::REGEX_NAME, $this->code, $match, 0, $this->cursor)) {
            $this->pushToken(Token::NAME_TYPE, $match[0]);
            $this->moveCursor($match[0]);
        }
        // numbers
        elseif (preg_match(self::REGEX_NUMBER, $this->code, $match, 0, $this->cursor)) {
            $this->pushToken(Token::NUMBER_TYPE, 0 + str_replace('_', '', $match[0]));
            $this->moveCursor($match[0]);
        }
        // punctuation
        elseif (str_contains(self::PUNCTUATION, $this->code[$this->cursor])) {
            // opening bracket
            if (str_contains('([{', $this->code[$this->cursor])) {
                $this->brackets[] = [$this->code[$this->cursor], $this->lineno];
            }
            // closing bracket
            elseif (str_contains(')]}', $this->code[$this->cursor])) {
                if (!$this->brackets) {
                    throw new SyntaxError(\sprintf('Unexpected "%s".', $this->code[$this->cursor]), $this->lineno, $this->source);
                }

                [$expect, $lineno] = array_pop($this->brackets);
                if ($this->code[$this->cursor] != strtr($expect, '([{', ')]}')) {
                    throw new SyntaxError(\sprintf('Unclosed "%s".', $expect), $lineno, $this->source);
                }
            }

            $this->pushToken(Token::PUNCTUATION_TYPE, $this->code[$this->cursor]);
            ++$this->cursor;
        }
        // strings
        elseif (preg_match(self::REGEX_STRING, $this->code, $match, 0, $this->cursor)) {
            $this->pushToken(Token::STRING_TYPE, $this->stripcslashes(substr($match[0], 1, -1), substr($match[0], 0, 1)));
            $this->moveCursor($match[0]);
        }
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
    # @param [String] char
    def code_at?(seek, char)
      @code[@cursor + seek] == char
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

      unary, binary = @environment.get_operators
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
