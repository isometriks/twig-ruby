# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::Range do
  # A range is an array in Twig, so it works wherever a sequence does
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% for i in (1..5)|reverse %}{{ i }}{% endfor %}
        {{ range(1, 3)|reverse|join }}
        {{ (1..3)[1] }}
        {{ (1..4)|slice(1, 2)|join }}
        {{ (1..3)|merge([9])|join }}
        {{ (1..3)|keys|join }}
        {{ (1..3)|json_encode|raw }}
        {{ range(1, 5, 2)|json_encode|raw }}
        {{ (1..3) is sequence ? "y" : "n" }}
        {{ ("a".."c")|join }}
        {{ (1..3)|last }}
        {{ (1..3) === [1, 2, 3] ? "y" : "n" }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        54321
        321
        2
        23
        1239
        012
        [1,2,3]
        [1,3,5]
        y
        abc
        3
        y
      OUTPUTS
    end
  end
end
