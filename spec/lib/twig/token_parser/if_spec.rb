# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::If do
  let(:inputs) do
    <<~INPUTS
      {% if true %}true{% endif %}
      {% if a %}a{% endif %}
      {% if b %}b{% else %}a{% endif %}
      {% if b %}b{% elsif a %}a{% endif %}
      {% if b %}b{% elseif a %}a{% endif %}
    INPUTS
  end

  let(:outputs) do
    <<~OUTPUTS
      true
      a
      a
      a
      a
    OUTPUTS
  end

  let(:locals) { { a: true, b: false } }

  it_behaves_like 'render_and_assert'
end
