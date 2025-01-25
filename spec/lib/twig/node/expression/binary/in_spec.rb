# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::In do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "Hello" in "Hello World" }}
        {{ 4 in [a] }}
        {{ a in [4] }}
        {{ 5 in [a, b] }}
        {{ a in "1234" }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        true
        true
        true
        true
        true
      OUTPUTS
    end

    let(:locals) { { a: 4, b: 5 } }
  end
end
