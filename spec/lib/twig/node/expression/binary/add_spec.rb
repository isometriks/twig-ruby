# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::Add do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ 1 + 2 }}
        {{ 1 + 2 + 3 }}
        {{ a + b }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        3
        6
        9
      OUTPUTS
    end

    let(:locals) { { a: 4, b: 5 } }
  end
end
