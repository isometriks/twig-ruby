# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Apply do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% apply upper %}Hello World!{% endapply %}
        {% apply upper %}{{ str }}{% endapply %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        HELLO WORLD!
        HELLO WORLD!
      OUTPUTS
    end

    let(:locals) { { str: 'Hello World!' } }
  end
end
