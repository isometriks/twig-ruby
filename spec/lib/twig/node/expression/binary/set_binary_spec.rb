# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::SetBinary do
  describe 'simple assignment' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          {% do b = 1 + 3 %}{{ b }}
          {{ b = 1 + 3 }}{{ b }}
          {% do c = d = "a" %}{{ c }}{{ d }}
          {% do a = (b = 4) + 5 %}{{ a }}{{ b }}
        INPUTS
      end

      let(:outputs) do
        <<~OUTPUTS
          4
          44
          aa
          94
        OUTPUTS
      end

      let(:locals) { {} }
    end
  end

  describe 'assignment in ternary' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do (c = 4) ? 0 : -1 %}{{ c }}' }
      let(:output) { '4' }
      let(:locals) { {} }
    end
  end

  describe 'assignment with named arguments' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{{ items|join(glue=", ") }}' }
      let(:output) { 'a, b, c' }
      let(:locals) { { items: %w[a b c] } }
    end
  end

  context 'when assigning to a non-variable' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{% do 5 = 3 %}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /Cannot assign to/ }
    end
  end
end
