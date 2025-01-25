# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::FloorDiv do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ 8 // 2 }}
        {{ 5 // 2 }}
        {{ 5.0 // 2.0 }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        4
        2
        2
      OUTPUTS
    end

    let(:locals) { { a: 4, b: 5 } }
  end
end
