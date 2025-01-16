# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Extends do
  let(:inputs) do
    <<~INPUTS
      {% extends "base" %}{% block original %}Hello{% endblock %}
    INPUTS
  end

  let(:outputs) do
    <<~OUTPUTS
      Hello World!
    OUTPUTS
  end

  let(:locals) { { template: 'include' } }

  it_behaves_like 'render_and_assert' do
    let(:templates) do
      {
        base: '{% block original %}Goodbye{% endblock %} World!',
      }
    end
  end
end
