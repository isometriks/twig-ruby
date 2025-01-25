# frozen_string_literal: false

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::NotIn do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "Hello" not in "Hello World" }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        false
        false
        false
        false
        false
      OUTPUTS
    end

    let(:locals) { { a: 4, b: 5 } }
  end
end
