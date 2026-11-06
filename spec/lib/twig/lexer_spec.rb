# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Lexer do
  let(:template) { '' }
  let(:loader) { Twig::Loader::Hash.new({ 'index.twig' => template }) }
  let(:environment) { Twig::Environment.new(loader) }
  let(:lexer) { described_class.new(environment) }
  let(:source) { loader.get_source_context('index.twig') }
  let(:tokens) { lexer.tokenize(source).debug }

  context 'when template has left single line line-trim' do
    let(:template) { ' {{~ "Hello World" }}  ' }

    it 'trims line whitespace' do
      expect(tokens).to eq([
        'var_start()',
        'string(Hello World)',
        'var_end()',
        'text(  )',
        'eof()',
      ])
    end
  end

  context 'when template has left multi line line-trim' do
    let(:template) { " \n {{~ 'Hello World' }}  " }

    it 'trims line whitespace' do
      expect(tokens).to eq([
        "text( \n)",
        'var_start()',
        'string(Hello World)',
        'var_end()',
        'text(  )',
        'eof()',
      ])
    end
  end

  context 'when template has left single line trim' do
    let(:template) { ' {{- "Hello World" }}  ' }

    it 'trims line whitespace' do
      expect(tokens).to eq([
        'var_start()',
        'string(Hello World)',
        'var_end()',
        'text(  )',
        'eof()',
      ])
    end
  end

  context 'when template has left multi line trim' do
    let(:template) { " \n {{- 'Hello World' }}  " }

    it 'trims line whitespace' do
      expect(tokens).to eq([
        'var_start()',
        'string(Hello World)',
        'var_end()',
        'text(  )',
        'eof()',
      ])
    end
  end

  context 'when template has right single line line-trim' do
    let(:template) { ' {{ "Hello World" ~}}  ' }

    it 'trims line whitespace' do
      expect(tokens).to eq([
        'text( )',
        'var_start()',
        'string(Hello World)',
        'var_end()',
        'eof()',
      ])
    end
  end

  context 'when template has right multi line line-trim' do
    let(:template) { " {{ 'Hello World' ~}} \n " }

    it 'trims line whitespace' do
      expect(tokens).to eq([
        'text( )',
        'var_start()',
        'string(Hello World)',
        'var_end()',
        "text(\n )",
        'eof()',
      ])
    end
  end

  context 'when template has right single line trim' do
    let(:template) { ' {{ "Hello World" -}}  ' }

    it 'trims line whitespace' do
      expect(tokens).to eq([
        'text( )',
        'var_start()',
        'string(Hello World)',
        'var_end()',
        'eof()',
      ])
    end
  end

  context 'when template has right multi line trim' do
    let(:template) { " {{ 'Hello World' -}} \n " }

    it 'trims line whitespace' do
      expect(tokens).to eq([
        'text( )',
        'var_start()',
        'string(Hello World)',
        'var_end()',
        'eof()',
      ])
    end
  end

  context 'when template has special char string literals' do
    let(:template) { '{{ "Hello\nWorld" }}' }

    it 'converts the special chars' do
      expect(tokens).to eq([
        'var_start()',
        "string(Hello\nWorld)",
        'var_end()',
        'eof()',
      ])
    end
  end

  context 'when template has verbatim tags' do
    let(:template) do
      <<~TEMPLATE.rstrip
        {%- verbatim -%}
        {{ 'bla' }}
        {%- endverbatim %}
      TEMPLATE
    end

    it 'parses verbatim tags' do
      expect(tokens).to eq([
        "text({{ 'bla' }})",
        'eof()',
      ])
    end
  end

  describe 'a name followed by ?' do
    def expression_tokens(code)
      described_class.
        new(environment).
        tokenize(Twig::Source.new(code, 'index.twig')).
        debug[1...-2]
    end

    {
      # The ? can't start a ternary here, so it's part of the name
      '{% if user_signed_in? %}' => ['name(if)', 'name(user_signed_in?)'],
      '{{ user_signed_in? }}' => ['name(user_signed_in?)'],
      '{{ user_signed_in? -}}' => ['name(user_signed_in?)'],
      '{{ user_signed_in?~}}' => ['name(user_signed_in?)'],
      '{% if a? and b? %}' => ['name(if)', 'name(a?)', 'operator(and)', 'name(b?)'],
      '{% if not a? or b? == c %}' => [
        'name(if)', 'operator(not)', 'name(a?)', 'operator(or)', 'name(b?)', 'operator(==)', 'name(c)'
      ],
      '{{ x? not in y }}' => ['name(x?)', 'operator(not in)', 'name(y)'],
      '{{ current_page?(x) }}' => ['name(current_page?)', 'operator(()', 'name(x)', 'punctuation())'],
      "{{ content_for?('x') }}" => ['name(content_for?)', 'operator(()', 'string(x)', 'punctuation())'],
      '{{ f(a?, b?) }}' => ['name(f)', 'operator(()', 'name(a?)', 'punctuation(,)', 'name(b?)', 'punctuation())'],
      '{{ [a?] }}' => ['operator([)', 'name(a?)', 'punctuation(])'],
      '{{ { k: a? } }}' => ['punctuation({)', 'name(k)', 'punctuation(:)', 'name(a?)', 'punctuation(})'],
      '{{ a?|default }}' => ['name(a?)', 'operator(|)', 'name(default)'],
      '{{ a? ? 1 : 2 }}' => ['name(a?)', 'operator(?)', 'number(1)', 'punctuation(:)', 'number(2)'],
      '{{ a ? b? : c }}' => ['name(a)', 'operator(?)', 'name(b?)', 'punctuation(:)', 'name(c)'],
      '{{ a? ?? b }}' => ['name(a?)', 'operator(??)', 'name(b)'],
      '{{ a.any? }}' => ['name(a)', 'operator(.)', 'name(any?)'],
      '{{ a.any? ? 1 : 2 }}' => [
        'name(a)', 'operator(.)', 'name(any?)', 'operator(?)', 'number(1)', 'punctuation(:)', 'number(2)'
      ],
      # Anything that can start an expression after the ? makes it a ternary,
      # as in Twig PHP
      '{{ x?1:2 }}' => ['name(x)', 'operator(?)', 'number(1)', 'punctuation(:)', 'number(2)'],
      '{{ x? y : z }}' => ['name(x)', 'operator(?)', 'name(y)', 'punctuation(:)', 'name(z)'],
      "{{ x?'y':'z' }}" => ['name(x)', 'operator(?)', 'string(y)', 'punctuation(:)', 'string(z)'],
      '{{ x? -1 : 1 }}' => ['name(x)', 'operator(?)', 'operator(-)', 'number(1)', 'punctuation(:)', 'number(1)'],
      '{{ x? not y }}' => ['name(x)', 'operator(?)', 'operator(not)', 'name(y)'],
      '{{ x?[1] }}' => ['name(x)', 'operator(?)', 'operator([)', 'number(1)', 'punctuation(])'],
      '{{ x? (y) }}' => ['name(x)', 'operator(?)', 'operator(()', 'name(y)', 'punctuation())'],
      # A symbol after the space keeps it a ternary, not the ? : alias of ?:
      '{{ x? :y : 2 }}' => ['name(x)', 'operator(?)', 'symbol(y)', 'punctuation(:)', 'number(2)'],
      '{{ x? :a : :b }}' => ['name(x)', 'operator(?)', 'symbol(a)', 'punctuation(:)', 'symbol(b)'],
      # A mapping key keeps its ? before the colon
      '{{ {visible?: true} }}' => [
        'punctuation({)', 'name(visible?)', 'punctuation(:)', 'name(true)', 'punctuation(})'
      ],
      '{{ {a: 1, x?:1} }}' => [
        'punctuation({)', 'name(a)', 'punctuation(:)', 'number(1)', 'punctuation(,)',
        'name(x?)', 'punctuation(:)', 'number(1)', 'punctuation(})'
      ],
      '{{ {k: x?:1} }}' => [
        'punctuation({)', 'name(k)', 'punctuation(:)', 'name(x)', 'operator(?:)', 'number(1)', 'punctuation(})'
      ],
      # An attribute keeps its ? before an operator that can go on with it
      '{{ a.b? - 1 }}' => ['name(a)', 'operator(.)', 'name(b?)', 'operator(-)', 'number(1)'],
      '{{ a.b?+ 1 }}' => ['name(a)', 'operator(.)', 'name(b?)', 'operator(+)', 'number(1)'],
      '{{ a.b?[1] }}' => ['name(a)', 'operator(.)', 'name(b?)', 'operator([)', 'number(1)', 'punctuation(])'],
      '{{ a.b? (1) }}' => ['name(a)', 'operator(.)', 'name(b?)', 'operator(()', 'number(1)', 'punctuation())'],
      '{{ a.b? 1 : 2 }}' => [
        'name(a)', 'operator(.)', 'name(b)', 'operator(?)', 'number(1)', 'punctuation(:)', 'number(2)'
      ],
      # Operators that start with ?
      '{{ a?:b }}' => ['name(a)', 'operator(?:)', 'name(b)'],
      '{{ a??b }}' => ['name(a)', 'operator(??)', 'name(b)'],
      '{{ a ?: b }}' => ['name(a)', 'operator(?:)', 'name(b)'],
      '{{ a ?? b }}' => ['name(a)', 'operator(??)', 'name(b)'],
      # ?. is the null-safe operator, as in Twig PHP, even straight after a name
      '{{ a?.b }}' => ['name(a)', 'operator(?.)', 'name(b)'],
      '{{ a ?. b }}' => ['name(a)', 'operator(?.)', 'name(b)'],
      '{{ user.admin?.x }}' => ['name(user)', 'operator(.)', 'name(admin)', 'operator(?.)', 'name(x)'],
      '{{ a?.b?.c }}' => ['name(a)', 'operator(?.)', 'name(b)', 'operator(?.)', 'name(c)'],
      '{{ f()?.b }}' => ['name(f)', 'operator(()', 'punctuation())', 'operator(?.)', 'name(b)'],
      # Parentheses, or a space between ? and ., keep the ? on a predicate
      '{{ (user.admin?).x }}' => [
        'operator(()', 'name(user)', 'operator(.)', 'name(admin?)', 'punctuation())', 'operator(.)', 'name(x)'
      ],
      '{{ a? .b }}' => ['name(a?)', 'operator(.)', 'name(b)'],
      # A ? and a . apart are still a ternary
      '{{ a ? .5 : 1 }}' => ['name(a)', 'operator(?)', 'operator(.)', 'number(5)', 'punctuation(:)', 'number(1)'],
    }.each do |code, expected|
      it "lexes #{code}" do
        expect(expression_tokens(code)).to eq(expected)
      end
    end
  end

  # Ported from Twig PHP's LexerTest::testLiteralIsNotAnOperator
  it 'does not lex literal as an operator' do
    tokens = described_class.new(environment).tokenize(Twig::Source.new('{{ literal }}', 'index')).debug

    expect(tokens).to eq(['var_start()', 'name(literal)', 'var_end()', 'eof()'])
  end

  # Ported from Twig PHP's LexerTest::testFilterAndAttributeNamedAfterOperator
  describe 'a filter or attribute named after an operator' do
    def stream(code)
      described_class.new(environment).tokenize(Twig::Source.new(code, 'index')).debug
    end

    it 'lexes it as a name after a pipe or a dot' do
      template = "{{ 'foo'|and }}{{ 'bar' | and }}{{ foo.and }}{{ bar . and }}{{ foo and bar }}"

      expect(stream(template)).to eq([
        'var_start()', 'string(foo)', 'operator(|)', 'name(and)', 'var_end()',
        'var_start()', 'string(bar)', 'operator(|)', 'name(and)', 'var_end()',
        'var_start()', 'name(foo)', 'operator(.)', 'name(and)', 'var_end()',
        'var_start()', 'name(bar)', 'operator(.)', 'name(and)', 'var_end()',
        'var_start()', 'name(foo)', 'operator(and)', 'name(bar)', 'var_end()',
        'eof()'
      ])
    end

    it_behaves_like 'render_and_assert' do
      let(:extensions) do
        extension = Class.new(Twig::Extension::Base) do
          def filters
            [Twig::TwigFilter.new('and', ->(value) { "#{value}&" }, is_safe: [:html])]
          end
        end

        [extension.new]
      end
      let(:locals) { { foo: { 'and' => 'attr' } } }
      let(:inputs) do
        [
          "{{ 'bar'|and }}",
          "{{ 'bar' | and }}",
          "{{ 'bar'| and }}",
          "{{ 'bar' |and }}",
          '{{ foo.and }}',
          '{{ foo . and }}',
          '{{ true and false ? 1 : 2 }}',
        ]
      end
      let(:outputs) { ['bar&', 'bar&', 'bar&', 'bar&', 'attr', 'attr', '2'] }
    end
  end

  describe 'number literals' do
    def number(code)
      described_class.new(environment).tokenize(Twig::Source.new("{{ #{code} }}", 'index')).tokens[1].value
    end

    {
      '10' => 10,
      '010' => 10,
      '007' => 7,
      '00' => 0,
      '1_000' => 1000,
      '0_10' => 10,
      '1.5' => 1.5,
      '01.50' => 1.5,
      '1_000.5' => 1000.5,
      '1e3' => 1000.0,
      '01e2' => 100.0,
    }.each do |code, value|
      it "lexes #{code} as #{value.inspect}" do
        expect(number(code)).to eql(value)
      end
    end

    it_behaves_like 'render_and_assert' do
      let(:inputs) { ['{{ 007 + 1 }}', '{{ {01: "a"}|keys|first }}{{ {01: "a"}[1] }}', '{{ [1, 2, 3][01] }}'] }
      let(:outputs) { %w[8 1a 2] }
    end
  end

  # Twig's byte-based name regex accepts every byte from \x7f, so any
  # multibyte UTF-8 character
  describe 'names with non-ASCII characters' do
    def stream(code)
      described_class.new(environment).tokenize(Twig::Source.new(code, 'index')).debug
    end

    it 'lexes them as names' do
      expect(stream('{{ имя }}{{ user.名前 }}{{ café? }}')).to eq([
        'var_start()', 'name(имя)', 'var_end()',
        'var_start()', 'name(user)', 'operator(.)', 'name(名前)', 'var_end()',
        'var_start()', 'name(café?)', 'var_end()',
        'eof()'
      ])
    end

    it 'keeps a ternary after them' do
      expect(stream('{{ имя ? 1 : 2 }}')).to eq([
        'var_start()', 'name(имя)', 'operator(?)', 'number(1)', 'punctuation(:)', 'number(2)', 'var_end()', 'eof()'
      ])
    end

    it_behaves_like 'render_and_assert' do
      let(:locals) { { user: { 'имя' => 'Пётр', '名前' => '太郎' } } }
      let(:inputs) do
        [
          '{% set имя = "Иван" %}{{ имя }}',
          '{{ user.имя }} {{ user.名前 }}',
          '{% for 項目 in [1, 2] %}{{ 項目 }}{% endfor %}',
          '{% macro 挨拶(名 = "x") %}{{ 名 }}{% endmacro %}{{ _self.挨拶("y") }}',
          '{% block ブロック %}b{% endblock %}',
        ]
      end
      let(:outputs) { ['Иван', 'Пётр 太郎', '12', 'y', 'b'] }
    end
  end

  describe 'CRLF line endings' do
    def render(code, **options)
      loader = Twig::Loader::Hash.new({ 'index.twig' => code })

      Twig::Environment.new(loader, options).load('index.twig').render({})
    end

    it 'counts each CRLF as one line' do
      expect { render("a\r\nb\r\n{{ x }}", strict_variables: true) }.
        to raise_error(Twig::Error::Runtime, /at line 3\.\z/)
    end

    it 'renders CRLF as a single newline' do
      expect(render("a\r\nb")).to eq("a\nb")
    end
  end

  describe 'token offsets' do
    def stream(code)
      described_class.new(environment).tokenize(Twig::Source.new(code, 'index'))
    end

    it 'points each token at the start of its lexeme in the source' do
      tokens = stream('Hello {{ name }}!').tokens

      expect(tokens.map { |token| [token.type, token.offset] }).to eq([
        [Twig::Token::TEXT_TYPE, 0],
        [Twig::Token::VAR_START_TYPE, 6],
        [Twig::Token::NAME_TYPE, 9],
        [Twig::Token::VAR_END_TYPE, 14],
        [Twig::Token::TEXT_TYPE, 16],
        [Twig::Token::EOF_TYPE, 17],
      ])
    end

    it 'allows recovering the raw expression source' do
      template = "Hello {{ name|upper ~ '!' }}"
      tokens = stream(template).tokens
      start = tokens.find { |token| token.type == Twig::Token::VAR_START_TYPE }.offset
      finish = tokens.find { |token| token.type == Twig::Token::VAR_END_TYPE }.offset

      expect(template[(start + 2)...finish].strip).to eq("name|upper ~ '!'")
    end

    it 'refers to the original source when line endings are normalized' do
      template = "Hello\r\n{{ name }}"
      tokens = stream(template).tokens

      expect(tokens.map { |token| [token.value, template[token.offset, 2]] }).to eq([
        ["Hello\n", 'He'],
        ['', '{{'],
        %w[name na],
        ['', '}}'],
        ['', ''],
      ])
    end

    it 'points block tag delimiters at the markers' do
      template = '{% set x = 1 %}'
      tokens = stream(template).tokens

      expect(template[tokens.first.offset, 2]).to eq('{%')
      expect(template[tokens.find { |token| token.type == Twig::Token::BLOCK_END_TYPE }.offset, 2]).to eq('%}')
    end

    it 'counts the offset in characters' do
      tokens = stream("\u00e9{{ x }}").tokens

      expect(tokens.map(&:offset)).to eq([0, 1, 4, 6, 8])
    end

    it 'gives synthetic tokens no offset' do
      expect(Twig::Token.new(Twig::Token::NAME_TYPE, 'foo', 1).offset).to be_nil
    end
  end

  describe 'CRLF line endings in tags' do
    def stream(code)
      described_class.new(environment).tokenize(Twig::Source.new(code, 'index')).debug
    end

    it 'swallows a CRLF after a block tag' do
      expect(stream("{% if x %}\r\na{% endif %}")).to eq([
        'block_start()', 'name(if)', 'name(x)', 'block_end()', 'text(a)',
        'block_start()', 'name(endif)', 'block_end()', 'eof()'
      ])
    end

    it 'normalizes newlines in strings and verbatim text' do
      expect(stream("{{ 'a\r\nb' ~ \"c\r\nd\" }}{% verbatim %}e\r\nf{% endverbatim %}")).to eq([
        'var_start()', "string(a\nb)", 'operator(~)', "string(c\nd)", 'var_end()', "text(e\nf)", 'eof()'
      ])
    end
  end

  describe 'syntax error columns' do
    def syntax_error(code)
      env = Twig::Environment.new(Twig::Loader::Hash.new({}))
      env.parse(env.tokenize(Twig::Source.new(code, 'index')))
    rescue Twig::Error::Syntax => e
      e
    else
      raise 'A syntax error should have been raised.'
    end

    it 'reports the column of a lexer error' do
      error = syntax_error("{{ 1 + 3) }}\n{{ ok }}")

      expect([error.lineno, error.column]).to eq([1, 9])
      expect(error.message).to end_with('at line 1 column 9.')
    end

    it 'reports the line and column of a closing delimiter on its own line' do
      error = syntax_error("{% from 'forms.twig'\n  %}")

      expect([error.lineno, error.column]).to eq([2, 3])
      expect(error.message).to end_with('at line 2 column 3.')
    end

    it 'counts the column in the original source' do
      error = syntax_error("x\r\n{{ 1__2 }}")

      expect([error.lineno, error.column]).to eq([2, 5])
      expect(error.message).to end_with('at line 2 column 5.')
    end

    {
      '{{ 1 + 3) }}' => [')', 9],
      '{{ obj] }}' => [']', 7],
      '{{ { a: 1 }}' => ['}', 12],
      '{{ ([1] + 3)) }}' => [')', 13],
    }.each do |code, (bracket, column)|
      it "reports the column of an unexpected #{bracket} in #{code}" do
        expect(syntax_error(code).message).to eq("Unexpected \"#{bracket}\" in \"index\" at line 1 column #{column}.")
      end
    end
  end

  describe 'escape sequences in interpolated strings' do
    def stream(code)
      described_class.new(environment).tokenize(Twig::Source.new(code, 'index')).debug
    end

    it 'unescapes them around an interpolation' do
      expect(stream("{{ \"a\\n\\\"\#{x}\\\#{y}\" }}")).to eq([
        'var_start()', "string(a\n\")", 'interpolation_start()', 'name(x)', 'interpolation_end()',
        "string(\#{y})", 'var_end()', 'eof()'
      ])
    end
  end

  describe 'hex and octal escapes in strings' do
    def values(code)
      described_class.new(environment).tokenize(Twig::Source.new(code, 'index')).tokens.
        select { |token| token.type == Twig::Token::STRING_TYPE }.map(&:value)
    end

    it 'gives bytes in the encoding of the source' do
      expect(values('{{ "\xc3\xa9" }}{{ \'\303\251\' }}{{ "é\x41" }}')).to eq(%w[é é éA])
      expect(values('{{ "\xc3\xa9" }}').first.encoding).to eq(Encoding::UTF_8)
    end

    it 'gives bytes in an interpolated string' do
      expect(values('{{ "é#{x}\xc3\xa9\303\251" }}')).to eq(%w[é éé])
    end

    it 'keeps a byte that is not valid in the encoding' do
      value = values('{{ "é\xff" }}').first

      expect(value.encoding).to eq(Encoding::UTF_8)
      expect(value.bytes).to eq([0xc3, 0xa9, 0xff])
    end

    it_behaves_like 'render_and_assert' do
      let(:locals) { { x: 1 } }
      let(:inputs) do
        [
          '{{ "\xc3\xa9" }}',
          '{{ "\303\251" ~ "é" }}',
          '{{ "é#{x}\xc3\xa9" }}',
          '{{ "\xc3\xa9"|upper }}',
          '{{ "é\xff"|raw }}',
        ]
      end
      let(:outputs) { ['é', 'éé', 'é1é', 'É', "é\xff"] }
    end

    # PHP reads such a string as bytes, so these give what Twig PHP gives
    context 'with a byte that is not valid in the encoding' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            %q({{ "\xff" in "a\xffb" ? 'y' : 'n' }}),
            %q({{ "\xff" not in "a\xffb" ? 'y' : 'n' }}),
            %q({{ "\xff" in "é\xff" ? 'y' : 'n' }}),
            %q({{ "é" in "é\xff" ? 'y' : 'n' }}),
            %q({{ "a\xffb"|replace({"\xff": "-"}) }}),
            %q({{ "a\xffb"|replace({"b": "é"})|raw }}),
            %q({{ "\xffa\xff"|trim("\xff") }}),
            %q({{ "é\xff"|trim|raw }}),
            %q({{ "a\xffb" matches '/\xff/' ? 'y' : 'n' }}),
            %q({{ "a\xffb" matches '/A\xff/i' ? 'y' : 'n' }}),
            %q({{ "é" matches '/\xc3/' ? 'y' : 'n' }}),
          ]
        end
        let(:outputs) { ['y', 'n', 'y', 'y', 'a-b', "a\xffé", 'a', "é\xff", 'y', 'y', 'y'] }
      end

      # PHP's mb_strtoupper differs here; the byte is kept, as it was
      # before such a string got the encoding of the source
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{{ "a\xffé"|upper|raw }}',
            '{{ "é\xffB"|lower|raw }}',
            '{{ "é\xffB"|capitalize|raw }}',
            '{{ "\xffaB"|capitalize|raw }}',
            '{{ "a\xffb"|plural|raw }}',
            '{{ "a\xffb"|striptags }}',
          ]
        end
        let(:outputs) { ["A\xffÉ", "é\xffb", "É\xffb", "\xffab", "a\xffbs", "a\u{fffd}b"] }
      end
    end
  end

  describe 'lexer errors' do
    def lexer_error(code)
      described_class.new(environment).tokenize(Twig::Source.new(code, 'index'))
    rescue Twig::Error::Syntax => e
      e.message
    else
      raise 'A syntax error should have been raised.'
    end

    it 'reports an unexpected character' do
      expect(lexer_error('{{ 1 ; }}')).to eq('Unexpected character ";" in "index" at line 1 column 6.')
    end

    it 'reports an unexpected character before a later comment' do
      expect(lexer_error('{{ 1 ; }}{# c #}')).to eq('Unexpected character ";" in "index" at line 1 column 6.')
    end

    it 'reports an unexpected character before a later single-quoted string' do
      expect(lexer_error("{{ 1 ; 'a' }}")).to eq('Unexpected character ";" in "index" at line 1 column 6.')
      expect(lexer_error("{{ 1 ; }}{{ 'a' }}")).to eq('Unexpected character ";" in "index" at line 1 column 6.')
      expect(lexer_error("{{ 'A' ~ ;b~'' }}")).to eq('Unexpected character ";" in "index" at line 1 column 10.')
    end

    it 'reports an unexpected character in an interpolation' do
      expect(lexer_error("{{ \"\#{1 ; }\" }}")).to eq('Unexpected character ";" in "index" at line 1 column 9.')
    end

    it 'reports an unexpected character in an interpolated string' do
      expect(lexer_error("{{ \"\#{a}\\")).to eq('Unexpected character "\\" in "index" at line 1 column 9.')
    end

    it 'reports an unclosed variable at its opening line' do
      expect(lexer_error("{{ 1 +\n\n  ")).to eq('Unclosed "variable" in "index" at line 1.')
    end

    it 'reports an unclosed block at its opening line' do
      expect(lexer_error("a\n{% if x\n\n  ")).to eq('Unclosed "block" in "index" at line 2.')
    end

    it 'reports an unclosed bracket at the end of the template' do
      expect(lexer_error("{{ (\n1")).to eq('Unclosed "(" in "index" at line 1.')
    end

    it 'reports an unclosed string at the end of the template' do
      expect(lexer_error("{{ \"a\#{b}")).to eq('Unclosed """ in "index" at line 1.')
    end

    it 'reports an unclosed verbatim block' do
      expect(lexer_error('{% verbatim %}x')).
        to eq('Unexpected end of file: Unclosed "verbatim" block in "index" at line 1.')
    end
  end

  it_behaves_like 'render_and_assert' do
    let(:input) do
      <<~INPUT.chomp
        **{% if true %}
        foo
        #{'    '}
            	    {%- endif %}**

        **

        	    {{- 'foo' }}**

        **
        #{'    '}
        #{'	'}
        {#- comment #}**

        **{% verbatim %}
        foo
        #{'    '}
            	    {%- endverbatim %}**
      INPUT
    end

    let(:output) do
      <<~OUTPUT.chomp
        **foo**

        **foo**

        ****

        **
        foo**
      OUTPUT
    end
  end
end
