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
end
