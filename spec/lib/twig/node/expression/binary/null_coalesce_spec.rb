# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::NullCoalesce do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "Hello" ?? "World" }}
        {{ nil ?? "Hello" }}
        {{ null ?? "Hello" }}
        {{ b ?? "Hello" }}
        {{ a ?? "Hello" }}
        {{ nil ?? html }}
        {{ nil ?? html|raw }}
        {{ html ?? "KO" }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello
        Hello
        Hello
        Hello
        false
        &lt;h1&gt;
        <h1>
        &lt;h1&gt;
        <h1>
      OUTPUTS
    end

    let(:locals) { { a: false, b: nil, html: '<h1>' } }
  end

  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ object.value ?? 99 }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        42
      OUTPUTS
    end

    let(:locals) do
      object = Class.new do
        attr_accessor :value

        def [](_nothing)
          nil
        end
      end.new

      object.value = 42

      {
        object:,
      }
    end
  end
end
