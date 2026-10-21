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
