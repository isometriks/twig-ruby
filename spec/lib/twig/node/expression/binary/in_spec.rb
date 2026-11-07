# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::In do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "Hello" in "Hello World" }}
        {{ 4 in [a] }}
        {{ a in [4] }}
        {{ 5 in [a, b] }}
        {{ a in "1234" }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        true
        true
        true
        true
        true
      OUTPUTS
    end

    let(:locals) { { a: 4, b: 5 } }
  end

  describe 'in compares with the values of a mapping, not its keys' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ "id" in {id: 5} ? "y" : "n" }}{{ 5 in {id: 5} ? "y" : "n" }}{{ 0 in {0: "a"} ? "y" : "n" }}',
          '{{ "admin" not in {admin: false} ? "y" : "n" }}{{ "a" in {a: null} ? "y" : "n" }}',
          '{{ null in {a: null} ? "y" : "n" }}',
        ]
      end
      let(:outputs) do
        %w[
          nyn
          yn
          y
        ]
      end
    end
  end

  describe 'in does not look inside nested sequences' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 2 in [[1, 2]] ? "y" : "n" }}{{ "x" in [["x", "y"]] ? "y" : "n" }}{{ [1] in [[1], 2] ? "y" : "n" }}',
        ]
      end
      let(:outputs) do
        [
          'nny',
        ]
      end
    end
  end

  describe 'in compares values like ==' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ "1" in [1] ? "y" : "n" }}{{ null in [0] ? "y" : "n" }}{{ null in [""] ? "y" : "n" }}',
          '{{ "" in [null] ? "y" : "n" }}{{ 2 in 1..3 ? "y" : "n" }}{{ "1e1" in [10] ? "y" : "n" }}',
          '{{ "b" in ["a", "b"]|filter(v => v) ? "y" : "n" }}',
        ]
      end
      let(:outputs) do
        %w[
          yyy
          yyy
          y
        ]
      end
    end
  end

  describe 'in only finds a string, number or symbol in a string' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ null in "abc" ? "y" : "n" }}{{ true in "true" ? "y" : "n" }}{{ 12 in "123" ? "y" : "n" }}',
        ]
      end
      let(:outputs) do
        [
          'nny',
        ]
      end
    end
  end

  describe 'in finds an object only as the same object' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) { ['{{ object in [object] ? "y" : "n" }}{{ object in [other, 1] ? "y" : "n" }}'] }
      let(:outputs) { ['yn'] }
      let(:locals) { { object: Object.new, other: Object.new } }
    end
  end
end
