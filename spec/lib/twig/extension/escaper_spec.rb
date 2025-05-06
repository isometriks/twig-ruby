# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Extension::Escaper do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "<h1>" }}
        {{ "<h1>"|e }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        <h1>
        &lt;h1&gt;
      OUTPUTS
    end
  end

  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      [
        '{{ "<h1>
hey</h1>"|nl2br }}',
        '{{ html|nl2br }}',
      ]
    end

    let(:outputs) do
      %W[
        <h1><br>\nhey</h1>
        &lt;h1&gt;<br>\nhey&lt;/h1&gt;
      ]
    end

    let(:locals) { { html: "<h1>\nhey</h1>" } }
  end
end
