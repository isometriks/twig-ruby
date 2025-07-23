# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::For do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% for i in numbers %}{{ i }}{% endfor %}
        {% for i in empty %}{{ i }}{% else %}empty{% endfor %}
        {% for x in [0, 1] %}{% for y in [0, 1] %}{{ x }}-{{ y }},{% endfor %}{% endfor %}
        {% for i in 0..3 %}{{ loop.cycle('even', 'odd') }}-{% endfor %}
        {% for i in [0, 1, 2] %}{{ loop.index0 }}{% endfor %}
        {% for i in [0, 1, 2] %}{{ loop.index }}{% endfor %}
        {% for x in [0, 1] %}{{ loop.index0 }}-{% for y in [0, 1, 2] %}{{ loop.index0 }}{% endfor %}{% endfor %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        123
        empty
        0-0,0-1,1-0,1-1,
        even-odd-even-odd-
        012
        123
        0-0121-012
      OUTPUTS
    end

    let(:locals) { { numbers: [1, 2, 3], empty: [] } }
  end
end
