# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Include do
  let(:inputs) do
    <<~INPUTS
      Hello {% include "include" %}
      Hello {% include template %}
      Hello {% include "deep" %}
    INPUTS
  end

  let(:outputs) do
    <<~OUTPUTS
      Hello World!
      Hello World!
      Hello World!
    OUTPUTS
  end

  let(:locals) { { template: 'include' } }
  let(:templates) do
    {
      include: 'World!',
      deep: '{% include "include" %}',
    }
  end

  it_behaves_like 'render_and_assert'
end
