module Twig
  class Lexer
    TAG_COMMENT = %w[{# #}]
    TAG_BLOCK = %w[{% %}]
    TAG_VARIABLE = %w[{{ }}]
    WHITESPACE_TRIM = "-".freeze
    WHITESPACE_LINE_TRIM = "~".freeze
    WHITESPACE_LINE_CHARS = " \t\0\x0B".freeze
    INTERPOLATION = %w[#{ }]

    REGEX_NAME = /[a-zA-Z_][a-zA-Z0-9_]*/

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
      end

      if (match = @code[@cursor..].match(REGEX_NAME))
        push_token(Token::NAME_TYPE, match.to_s)
        move_cursor(match.to_s)
      end
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
  end
end
