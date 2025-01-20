# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Yield do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% yield basic() do %}Hello World!{% endyield %}
        {% yield basic() do |q| %}Hello World!{% endyield %}
        {% yield pair() do |k, v| %}{{ k }} {{ v }}{% endyield %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello World!
      OUTPUTS
    end

    let(:locals) { { a: %w[Hello World!] } }

    let(:call_context) do
      Class.new do
        def basic
          yield

          nil
        end

        def pair
          yield %w[Hello World!]

          nil
        end
      end.new
    end

    let(:extensions) do
      [
        Class.new(Twig::Extension::Base) do
          def helper_methods
            %i[basic pair]
          end
        end.new,
      ]
    end
  end
end
