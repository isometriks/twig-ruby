# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::EndsWith do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "Hello World" ends with "World" }}
        {{ "Hello World" ends with a }}
        {{ "Hello World" ends with b }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        true
        false
        true
      OUTPUTS
    end

    let(:locals) { { a: 'Hello', b: 'World' } }
  end
end
