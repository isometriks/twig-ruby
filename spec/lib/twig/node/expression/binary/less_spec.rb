require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::Less do
  let(:inputs) do
    <<~INPUTS
      {{ 1 < 2 }}
      {{ 2 < 1 }}
      {{ 1 < 1 }}
      {{ a < b }}
    INPUTS
  end

  let(:outputs) do
    <<~OUTPUTS
      true
      false
      false
      true
    OUTPUTS
  end

  let(:locals) { { a: 'a', b: 'b' } }

  it_behaves_like 'render_and_assert'
end
