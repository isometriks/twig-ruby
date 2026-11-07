# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::AutoEscape do
  it_behaves_like 'render_and_assert' do
    let(:options) { { autoescape: false } }

    let(:inputs) do
      <<~INPUTS
        {% autoescape false %}<h1>Hello World!</h1>{% endautoescape %}
        {% autoescape false %}{{ html }}{% endautoescape %}
        {% autoescape "html" %}<h1>Hello World!</h1>{% endautoescape %}
        {% autoescape "html" %}{{ html }}{% endautoescape %}
        {% autoescape :html %}{{ html }}{% endautoescape %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        <h1>Hello World!</h1>
        <h1>Hello World!</h1>
        <h1>Hello World!</h1>
        &lt;h1&gt;Hello World!&lt;/h1&gt;
        &lt;h1&gt;Hello World!&lt;/h1&gt;
      OUTPUTS
    end

    let(:locals) do
      {
        html: '<h1>Hello World!</h1>',
      }
    end
  end

  {
    'a number' => '{% autoescape 1 %}{% endautoescape %}',
    'a variable' => "{% autoescape\nstrategy %}{% endautoescape %}",
  }.each do |kind, code|
    context "with #{kind} as the strategy" do
      it_behaves_like 'render_and_raise' do
        let(:template) { code }
        let(:error) { Twig::Error::Syntax }
        let(:message) { /\AAn escaping strategy must be a string or false in "template\.twig" at line \d\.\z/ }
      end
    end
  end

  it 'reports an invalid strategy at the line of its expression' do
    loader = Twig::Loader::Hash.new({ 'index.twig' => "{% autoescape\n\n1 %}{% endautoescape %}" })
    environment = Twig::Environment.new(loader)

    expect { environment.load('index.twig') }.
      to raise_error(Twig::Error::Syntax, 'An escaping strategy must be a string or false in "index.twig" at line 3.')
  end
end
