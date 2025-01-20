# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::For do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% for i in numbers %}{{ i }}{% endfor %}
        {% for i in empty %}{{ i }}{% else %}empty{% endfor %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        123
        empty
      OUTPUTS
    end

    let(:locals) { { numbers: [1, 2, 3], empty: [] } }
  end
end
