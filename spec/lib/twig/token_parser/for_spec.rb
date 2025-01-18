# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::For do
  let(:inputs) do
    <<~INPUTS
      {% for i in numbers %}{{ i }}{% endfor %}
    INPUTS
  end

  let(:outputs) do
    <<~OUTPUTS
      123
    OUTPUTS
  end

  let(:locals) { { numbers: [1, 2, 3] } }

  it_behaves_like 'render_and_assert'
end
