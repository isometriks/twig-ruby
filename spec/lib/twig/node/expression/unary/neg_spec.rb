require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Unary::Neg do
  let(:inputs) do
    <<~INPUTS
      {{ -a }}
      {{ -a + (-b) }}
      {{ -(-a + (-b)) }}
    INPUTS
  end

  let(:outputs) do
    <<~OUTPUTS
      -4
      -9
      9
    OUTPUTS
  end

  let(:locals) { { a: 4, b: 5 } }

  it_behaves_like "render_and_assert"
end
