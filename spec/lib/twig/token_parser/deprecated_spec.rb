# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::TokenParser::Deprecated do
  it 'outputs a deprecation warning' do
    loader = Twig::Loader::Hash.new({
      'index.twig' => '{% deprecated "Use base.twig instead" version="1.0" package="twig" %}',
    })
    environment = Twig::Environment.new(loader)

    expect do
      environment.load('index.twig').render
    end.to(
      output("Deprecation Notice: Use base.twig instead in index.twig on line 1 (Package: twig) (Version: 1.0)\n").
        to_stdout
    )
  end

  it 'raises a syntax error for an unknown option' do
    loader = Twig::Loader::Hash.new({ 'index' => "{% deprecated 'x' foo = 'b' %}" })

    expect { Twig::Environment.new(loader).load('index') }.
      to raise_error(Twig::Error::Syntax, 'Unknown "foo" option in "index" at line 1.')
  end
end
