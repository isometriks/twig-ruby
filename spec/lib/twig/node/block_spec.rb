# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Block do
  let(:inputs) do
    <<~INPUTS
      {% block test %}Hello World!{% endblock %}
      {% block test %}Hello World!{% endblock test %}
    INPUTS
  end

  let(:outputs) do
    <<~OUTPUTS
      Hello World!
      Hello World!
    OUTPUTS
  end

  let(:locals) { {} }

  it_behaves_like 'render_and_assert'
end
