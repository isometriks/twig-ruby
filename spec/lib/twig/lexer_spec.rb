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
    }.each do |code, expected|
      it "lexes #{code}" do
        expect(expression_tokens(code)).to eq(expected)
      end
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
