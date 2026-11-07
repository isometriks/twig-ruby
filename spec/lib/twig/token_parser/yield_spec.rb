# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Yield do
  it_behaves_like 'render_and_assert' do
    let(:options) { { allow_helper_methods: true } }

    let(:inputs) do
      <<~INPUTS
        {% yield basic() do %}Hello World!{% endyield %}
        {% yield basic() do |q| %}Hello World!{% endyield %}
        {% yield pair() do |k, v| %}{{ k }} {{ v }}{% endyield %}
        {% yield pair do |k, v| %}{{ k }} {{ v }}{% endyield %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
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
        end

        def pair
          yield %w[Hello World!]
        end
      end.new
    end
  end

  describe 'yielding to a call with a spread' do
    it_behaves_like 'render_and_assert' do
      let(:options) { { allow_helper_methods: true, autoescape: false } }

      let(:extensions) do
        [
          Class.new(Twig::Extension::Base) do
            def functions
              [Twig::TwigFunction.new('wrap_fn', ->(tag = 'div', &blk) { "<#{tag}>#{blk&.call('F')}</#{tag}>" })]
            end
          end.new,
        ]
      end

      let(:inputs) do
        [
          "{% yield wrap(...['p'], ...{cls: 'x'}) do |f| %}{{ f }}{% endyield %}",
          '{% yield wrap(...args) do |f| %}{{ f }}{% endyield %}',
          "{% yield wrap_fn(...['p']) do |f| %}{{ f }}{% endyield %}",
        ]
      end

      let(:outputs) { ['<p class=x>F</p>', '<p class=c>F</p>', '<p>F</p>'] }
      let(:locals) { { args: ['p'] } }

      let(:call_context) do
        Class.new do
          def wrap(tag = 'div', cls: 'c')
            "<#{tag} class=#{cls}>#{yield 'F'}</#{tag}>"
          end
        end.new
      end
    end
  end

  context 'with a block argument ending in ?' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{% yield pair do |k, v?| %}{{ k }}{% endyield %}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /A yield block argument cannot end with "\?" \("v\?"\)/ }
    end
  end
end
