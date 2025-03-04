# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Guard do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% guard function importmap %}KO{% else %}OK{% endguard %}
        {% guard function include %}OK{% else %}KO{% endguard %}
        {% guard function importmap %}{{ fake_function()|fake_filter is fake_test }}{% else %}OK{% endguard %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        OK
        OK
        OK
      OUTPUTS
    end

    let(:locals) { { a: true, b: false } }
  end
end
