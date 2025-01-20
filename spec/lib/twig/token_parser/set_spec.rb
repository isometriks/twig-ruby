# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Set do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% set message = "Hello World!" %}{{ message }}
        {% set hello, world = "Hello", "World!" %}{{ hello }} {{ world }}
        {% set message %}Hello World!{% endset %}{{ message }}
        {% set captured %}{{ message }}{% endset %}{{ captured }}
        {% set captured %}<p>Hello World!</p>{% endset %}{{ captured }}
        {% set captured %}{{ html }}{% endset %}{{ captured }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        <p>Hello World!</p>
        &lt;p&gt;Hello World!&lt;/p&gt;
      OUTPUTS
    end

    let(:locals) { { message: 'Hello World!', html: '<p>Hello World!</p>' } }
  end
end
