# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Ternary do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ true ? "a" : "b" }}
        {{ false ? "a" : (false ? "b" : "c") }}
        {{ true ? "a" }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        a
        c
        a
      OUTPUTS
    end
  end
end
