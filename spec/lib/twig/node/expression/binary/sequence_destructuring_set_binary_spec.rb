# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::SequenceDestructuringSetBinary do
  describe 'basic array destructuring' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do [first, last] = names %}{{ first }} {{ last }}' }
      let(:output) { 'Fabien Potencier' }
      let(:locals) { { names: %w[Fabien Potencier] } }
    end
  end

  describe 'swap values' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do a = "x" %}{% do b = "y" %}{% do [a, b] = [b, a] %}{{ a }}{{ b }}' }
      let(:output) { 'yx' }
      let(:locals) { {} }
    end
  end

  describe 'skipping elements with empty slots' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do [, second] = items %}{{ second }}' }
      let(:output) { 'second' }
      let(:locals) { { items: %w[first second] } }
    end
  end

  describe 'destructuring with fewer values pads with nil' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do [x, y, z] = items %}{{ x }} {{ y }} {{ z is same as(null) ? "null" : z }}' }
      let(:output) { 'one two null' }
      let(:locals) { { items: %w[one two] } }
    end
  end

  describe 'destructuring from inline array' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do [a, b, c] = [1, 2, 3] %}{{ a }}{{ b }}{{ c }}' }
      let(:output) { '123' }
      let(:locals) { {} }
    end
  end

  context 'when destructuring to a non-variable' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{% do [1, b] = [1, 2] %}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /only variables can be assigned in destructuring/ }
    end
  end
end
