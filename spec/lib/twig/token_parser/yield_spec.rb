# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Yield do
  let(:inputs) do
    <<~INPUTS
      {% yield basic() do |q| %}Hello World!{% endyield %}
    INPUTS
  end

  let(:outputs) do
    <<~OUTPUTS
      Hello World!
    OUTPUTS
  end

  let(:locals) { {} }

  it_behaves_like 'render_and_assert' do
    let(:call_context) do
      Class.new do
        def basic
          yield

          nil
        end
      end.new
    end

    let(:extensions) do
      [
        Class.new(Twig::Extension::Base) do
          def helper_methods
            ['basic']
          end
        end.new,
      ]
    end
  end
end
