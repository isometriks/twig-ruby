# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Yield do
  it_behaves_like 'render_and_assert' do
    let(:options) { { allow_helper_methods: true } }

    let(:inputs) do
      <<~INPUTS
        {{ a }}{% do upper(a) %}{{ a }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        helloHELLO
      OUTPUTS
    end

    let(:locals) { { a: +'hello' } }

    let(:call_context) do
      Class.new do
        def upper(var)
          var.upcase!
        end
      end.new
    end

    let(:extensions) do
      [
        Class.new(Twig::Extension::Base) do
          def helper_methods
            %i[upper]
          end
        end.new,
      ]
    end
  end
end
