# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::TokenParser::Deprecated do
  it 'outputs a deprecation warning' do
    loader = Twig::Loader::Array.new({
      'index.twig' => '{% deprecated "Use base.twig instead" version="1.0" package="twig" %}',
    })
    environment = Twig::Environment.new(loader)

    expect do
      environment.load_template('index.twig').render
    end.to(
      output("Deprecation Notice: Use base.twig instead in index.twig on line 1 (Package: twig) (Version: 1.0)\n").
        to_stdout
    )
  end
end
