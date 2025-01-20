# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::Spaceship do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ 1 <=> 2 }}
        {{ 1 <=> 1 }}
        {{ 2 <=> 1 }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        -1
        0
        1
      OUTPUTS
    end

    let(:locals) { { a: 4, b: 5 } }
  end
end
