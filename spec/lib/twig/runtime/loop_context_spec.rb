# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Runtime::LoopContext do
  it_behaves_like 'render_and_assert' do
    let(:input) do
      <<~INPUT
        {% for value in values %}
          {{ value }} - {{ value }} != {{ loop.previous }} ? {{ loop.changed(value) }}
        {% endfor %}
      INPUT
    end

    let(:output) do
      <<-OUTPUT
  0 - 0 !=  ? true
  1 - 1 != 0 ? true
  1 - 1 != 1 ? false
  2 - 2 != 1 ? true
  3 - 3 != 2 ? true
      OUTPUT
    end

    let(:locals) { { values: [0, 1, 1, 2, 3] } }
  end
end
