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

  describe 'destructuring from an enumerable' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do [a, , c, d] = items %}{{ a }}{{ c }}{{ d is same as(null) ? "null" : d }}' }
      let(:output) { '13null' }
      let(:locals) { { items: (1..3).each } }
    end
  end

  describe 'destructuring stops consuming an enumerable once every name is set' do
    let(:items) do
      Enumerator.new do |yielder|
        yielder << 'first'
        yielder << 'second'
        raise 'consumed too many items'
      end
    end

    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do [a, b] = items %}{{ a }} {{ b }}' }
      let(:output) { 'first second' }
      let(:locals) { { items: } }
    end
  end

  describe 'destructuring from a mapping uses integer keys' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do [a, b, c] = {1: "b", 0: "a", x: "c"} %}{{ a }}{{ b }}{{ c is null ? "null" : c }}' }
      let(:output) { 'abnull' }
      let(:locals) { {} }
    end
  end

  describe 'destructuring a filtered sequence takes its values' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do [a, b] = [10, 20, 30]|filter(x => x > 5) %}[{{ a }}][{{ b }}]' }
      let(:output) { '[10][20]' }
      let(:locals) { {} }
    end
  end

  ['5', '"str"', 'null'].each do |source|
    describe "destructuring from #{source}" do
      it_behaves_like 'render_and_raise' do
        let(:template) { "{% do [a, b] = #{source} %}" }
        let(:error) { Twig::Error::Runtime }
        let(:message) { /Sequence destructuring expects a sequence or a mapping, got "\w+"/ }
      end
    end
  end

  describe 'destructuring nested inside an expression' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do x = ([p, q] = items) %}{{ p }}{{ q }} {{ x|join(",") }}' }
      let(:output) { '12 1,2,3' }
      let(:locals) { { items: [1, 2, 3] } }
    end
  end

  describe 'returning the sequence padded to the number of names' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{{ ([a, b, c] = ["x"])|length }}' }
      let(:output) { '3' }
      let(:locals) { {} }
    end
  end

  describe 'returning an enumerable as it was given' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{{ ([a] = items) is same as(items) ? "same" : "different" }}' }
      let(:output) { 'same' }
      let(:locals) { { items: (1..3).each } }
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
