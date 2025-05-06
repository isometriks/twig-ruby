# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Extension::Debug do
  it_behaves_like 'render_and_assert' do
    let(:extensions) { [Twig::Extension::Debug.new] }
    let(:inputs) do
      <<~INPUTS
        {{ dump(hash)|raw }}
        {{ dump()|raw }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        {hello: "World"}
        {hash: {hello: "World"}}
      OUTPUTS
    end

    let(:locals) do
      {
        hash: { hello: 'World' },
      }
    end
  end
end
