# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::In do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "12345" matches "\d+" }}
        {{ "12345" matches "/\\d+/" }}
        {{ a matches "/\\d+/" }}
        {{ "HELLO" matches "/[a-z]+/i" }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        true
        true
        true
        true
      OUTPUTS
    end

    let(:locals) { { a: 456 } }
  end
end
