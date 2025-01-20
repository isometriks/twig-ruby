# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Set do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% set message = "Hello World!" %}{{ message }}
        {% set hello, world = "Hello", "World!" %}{{ hello }} {{ world }}
        {% set message %}Hello World!{% endset %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello World!
      OUTPUTS
    end

    let(:locals) { {} }
  end
end
