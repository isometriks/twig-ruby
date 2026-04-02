# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::SameAs do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ 1 === 1 ? "OK" }}
        {{ 1 !== true ? "OK" }}
        {{ "a" === "a" ? "OK" }}
        {{ null === null ? "OK" }}
        {{ 1 !== "1" ? "OK" }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        OK
        OK
        OK
        OK
        OK
      OUTPUTS
    end

    let(:locals) { {} }
  end
end
