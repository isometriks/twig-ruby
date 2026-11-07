# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Parser do
  it 'raises an error when template with parent has body content' do
    environment = Twig::Environment.new(Twig::Loader::Hash.new({}))
    source = Twig::Source.new('{% extends "base.twig" %}Contents with parent', :test, '/test.twig')
    lexer = Twig::Lexer.new(environment)
    parser = described_class.new(environment)

    expect do
      parser.parse(lexer.tokenize(source))
    end.to raise_error(
      Twig::Error::Syntax,
      /A template that extends another one cannot include content outside Twig blocks./i
    )
  end

  it 'raises an error for a second extends tag' do
    environment = Twig::Environment.new(Twig::Loader::Hash.new({}))
    source = Twig::Source.new("{% extends 'a' %}\n{% extends 'b' %}", 'index')
    lexer = Twig::Lexer.new(environment)
    parser = described_class.new(environment)

    expect do
      parser.parse(lexer.tokenize(source))
    end.to raise_error(Twig::Error::Syntax, 'Multiple extends tags are forbidden in "index" at line 2.')
  end

  describe 'unknown callables and tags' do
    def syntax_error(code)
      Twig::Environment.new(Twig::Loader::Hash.new({ 'index' => code })).load('index')
    rescue Twig::Error::Syntax => e
      e.message
    else
      raise 'A syntax error should have been raised.'
    end

    # Ported from Twig PHP's ParserTest and ExpressionParserTest
    it 'suggests the names that look like the unknown one' do
      expect(syntax_error('{% foo %}')).to eq('Unknown "foo" tag. Did you mean "for" in "index" at line 1?')
      expect(syntax_error('{{ cycl() }}')).
        to eq('Unknown "cycl" function. Did you mean "cycle" in "index" at line 1?')
      expect(syntax_error('{{ 1|lowe }}')).to eq('Unknown "lowe" filter. Did you mean "lower" in "index" at line 1?')
      expect(syntax_error('{{ 1 is evn }}')).to eq('Unknown "evn" test. Did you mean "even" in "index" at line 1?')
      expect(syntax_error('{{ 1 is same }}')).
        to eq('Unknown "same" test. Did you mean "same as" in "index" at line 1?')
    end

    it 'quotes the name of an unknown filter or test' do
      expect(syntax_error('{{ 1|foobar }}')).to eq('Unknown "foobar" filter in "index" at line 1.')
      expect(syntax_error('{{ 1 is foobar }}')).to eq('Unknown "foobar" test in "index" at line 1.')
      expect(syntax_error('{{ 1 is nope nope }}')).to eq('Unknown "nope nope" test in "index" at line 1.')
    end
  end
end
