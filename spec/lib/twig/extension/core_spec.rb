# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Extension::Core do
  context 'filters' do
    let(:inputs) do
      <<~INPUTS
        Hello {{ name|capitalize }}!
        Hello {{ name|upper }}!
        {{ "HeLLo WoRlD!"|lower }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello WORLD!
        hello world!
      OUTPUTS
    end

    let(:locals) { { name: 'world', line: "Hello\nWorld!" } }

    it_behaves_like 'render_and_assert'
  end
end
