# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::BitwiseAnd do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ 6 b-and 3 }}
        {{ 1 b-or 2 b-and 4 }}
        {{ 4 b-and 2 b-or 1 }}
        {{ 6 b-xor 3 b-and 5 }}
        {{ 1 b-xor 3 b-and 2 }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        2
        1
        1
        7
        3
      OUTPUTS
    end
  end
end
