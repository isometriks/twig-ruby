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
end
