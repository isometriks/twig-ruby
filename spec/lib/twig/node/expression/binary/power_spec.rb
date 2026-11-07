# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::Power do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ 2 ** 3 }}
        {{ 2 ** 0 }}
        {{ 2 ** -1 }}
        {{ (-2) ** -3 }}
        {{ 10 ** -2 }}
        {{ a ** b }}
        {{ 0 ** -1 }}
        {{ 2 ** 0.5 }}
        {{ 2.5 ** 2 }}
        {{ 2.0 ** -1 }}
        {{ (-8) ** 0.5 }}
        {{ -2 ** 2 }}
        {{ (-2) ** 2 }}
        {{ -2 ** -1 }}
        {{ - -2 ** 2 }}
        {{ 2 ** -2 ** 2 }}
        {{ -a ** 0 }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        8
        1
        0.5
        -0.125
        0.01
        0.0625
        INF
        1.4142135623731
        6.25
        0.5
        NAN
        -4
        4
        -0.5
        4
        0.0625
        -1
      OUTPUTS
    end

    let(:locals) { { a: 4, b: -2 } }
  end
end
