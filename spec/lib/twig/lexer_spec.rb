# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Lexer do
  let(:template) { '' }
  let(:loader) { Twig::Loader::Array.new({ 'index.twig' => template }) }
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
