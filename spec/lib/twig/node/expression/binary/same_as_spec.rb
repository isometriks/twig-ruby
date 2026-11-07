# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::SameAs do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ 1 === 1 ? "OK" }}
        {{ 1 !== true ? "OK" }}
        {{ "a" === "a" ? "OK" }}
        {{ null === null ? "OK" }}
        {{ 1 !== "1" ? "OK" }}
        {{ 1 === 1.0 ? "KO" : "OK" }}
        {{ 1 !== 1.0 ? "OK" }}
        {{ 1 is same as(1.0) ? "KO" : "OK" }}
        {{ 1 is not same as(1.0) ? "OK" }}
        {{ [1] === [1] ? "OK" }}
        {{ [1] === [1.0] ? "KO" : "OK" }}
        {{ [[1, {a: [2]}]] === [[1, {a: [2]}]] ? "OK" }}
        {{ {a: 1, b: 2} === {a: 1, b: 2} ? "OK" }}
        {{ {a: 1, b: 2} === {b: 2, a: 1} ? "KO" : "OK" }}
        {{ {a: {x: 1, y: 2}} === {a: {y: 2, x: 1}} ? "KO" : "OK" }}
        {{ false === null ? "KO" : "OK" }}
        {{ object === same ? "OK" }}
        {{ object === other ? "KO" : "OK" }}
        {{ object is same as(other) ? "KO" : "OK" }}
        {{ object !== other ? "OK" }}
        {{ 0_0 === 0 ? "OK" }}
        {{ 007 is same as(7) ? "OK" }}
      INPUTS
    end

    let(:outputs) do
      (['OK'] * 22).join("\n")
    end

    let(:locals) do
      object = Object.new

      { object:, same: object, other: Object.new }
    end
  end

  describe 'a sequence and a mapping, which are both PHP arrays' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          {{ [1, 2] === {0: 1, 1: 2} ? "y" : "n" }}
          {{ (1..3) === [1, 2, 3] ? "y" : "n" }}
          {{ ([1, 2, 3]|filter(x => x > 0)) === [1, 2, 3] ? "y" : "n" }}
          {{ ([1, 2, 3]|filter(x => x > 1)) === {1: 2, 2: 3} ? "y" : "n" }}
          {{ {a: 1} === {"a": 1} ? "y" : "n" }}
          {{ {"1": 1} === {1: 1} ? "y" : "n" }}
          {{ [1, 2] === {1: 2, 0: 1} ? "y" : "n" }}
          {{ [[1]] === [{0: 1}] ? "y" : "n" }}
          {{ [1] is same as({0: 1}) ? "y" : "n" }}
          {{ [1] !== {0: 1} ? "y" : "n" }}
          {{ {0: 1} === [1.0] ? "y" : "n" }}
        INPUTS
      end

      let(:outputs) { %w[y y y y y y n y y n n] }
    end
  end
end
