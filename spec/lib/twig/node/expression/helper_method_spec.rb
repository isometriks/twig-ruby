# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Call do
  it_behaves_like 'render_and_assert' do
    let(:options) { { allow_helper_methods: true } }

    let(:call_context) do
      Class.new do
        def greeting
          'Hello World!'
        end
      end.new
    end

    let(:inputs) do
      <<~INPUTS
        {{ greeting }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
      OUTPUTS
    end
  end

  describe 'spreading into a helper method' do
    it_behaves_like 'render_and_assert' do
      let(:options) { { allow_helper_methods: true, autoescape: false } }

      let(:call_context) do
        Class.new do
          def tag(name = 'div', cls: 'c') = "<#{name} class=#{cls}>"
        end.new
      end

      let(:inputs) do
        [
          '{{ tag(...args) }}',
          "{{ tag(...['p']) }}",
          "{{ tag(...{cls: 'x'}) }}",
          "{{ tag('p', ...opts) }}",
        ]
      end

      let(:outputs) { ['<p class=c>', '<p class=c>', '<div class=x>', '<p class=y>'] }
      let(:locals) { { args: ['p'], opts: { cls: 'y' } } }
    end
  end
end
