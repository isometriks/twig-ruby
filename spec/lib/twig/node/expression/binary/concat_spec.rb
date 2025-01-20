# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::Concat do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "Hello " ~ "World!" }}
        {{ a ~ b }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
      OUTPUTS
    end

    let(:locals) { { a: 'Hello ', b: 'World!' } }
  end
end
