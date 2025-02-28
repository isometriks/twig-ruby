# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::StartsWith do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "Hello World" starts with "Hello" }}
        {{ "Hello World" starts with a }}
        {{ "Hello World" starts with b }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        true
        true
        false
      OUTPUTS
    end

    let(:locals) { { a: 'Hello', b: 'World' } }
  end

  context 'multi line' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          "{{ 'foo' starts
                  with 'f' ? 'OK' : 'KO' }}",
        ]
      end

      let(:outputs) do
        [
          'OK',
        ]
      end
    end
  end
end
