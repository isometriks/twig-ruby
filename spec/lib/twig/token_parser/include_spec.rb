# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Include do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        Hello {% include "include" %}
        Hello {% include "include" only %}
        Hello {% include template %}
        Hello {% include "deep" %}
        Hello-{% include "missing" ignore missing %}-World!
        {% include "vars" with { var: "Hello World!" } %}
        {% include "vars" ignore missing with { var: "Hello World!" } %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        Hello--World!
        Hello World!
        Hello World!
      OUTPUTS
    end

    let(:locals) { { template: 'include' } }

    let(:templates) do
      {
        include: 'World!',
        deep: '{% include "include" %}',
        vars: '{{ var }}',
      }
    end
  end
end
