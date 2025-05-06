# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::Elvis do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "OK" ?: "KO" }}
        {{ nil ?: "OK" }}
        {{ false ?: "OK" }}
        {{ a ?: "OK" }}
        {{ b ?: "OK" }}
        {{ html ?: "KO" }}
        {{ html|raw ?: "KO" }}
        {{ false ?: html }}
        {{ false ?: html|raw }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        OK
        OK
        OK
        OK
        OK
        &lt;h1&gt;
        <h1>
        &lt;h1&gt;
        <h1>
      OUTPUTS
    end

    let(:locals) { { a: false, b: nil, html: '<h1>' } }
  end
end
