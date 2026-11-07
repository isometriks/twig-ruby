# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::TokenParser::Block do
  it 'raises a syntax error for an endblock with another name' do
    loader = Twig::Loader::Hash.new({ 'index' => "{% block a %}\nA\n{% endblock\nb\n%}" })

    expect { Twig::Environment.new(loader).load('index') }.
      to raise_error(
        Twig::Error::Syntax,
        'Expected endblock for block "a" (but "b" given) in "index" at line 5.'
      )
  end
end
