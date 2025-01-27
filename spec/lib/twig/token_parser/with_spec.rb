# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::With do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% with { str: "Hello" } only %}{{ str }}{% endwith %} {{ str }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello World!
      OUTPUTS
    end

    let(:locals) { { str: 'World!' } }
  end
end
