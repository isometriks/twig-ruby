require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Unary::Neg do
  let(:inputs) do
    <<~INPUTS
      {{ not a ? "a" : "b" }}
      {{ not not a ? "a" : "b" }}
      {{ a and not b ? "true" : "false" }}
    INPUTS
  end

  let(:outputs) do
    <<~OUTPUTS
      b
      a
      true
    OUTPUTS
  end

  let(:locals) { { a: true, b: false } }

  it_behaves_like 'render_and_assert'
end
