# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::Mod do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ 7 % 2 }}
        {{ -7 % 2 }}
        {{ 7 % -2 }}
        {{ -7 % -2 }}
        {{ 5.5 % 2 }}
        {{ -5.5 % 2 }}
        {{ 7 % 2.9 }}
        {{ b % a }}
        {{ "7" % 2 }}
        {{ 7 % "2" }}
        {{ "7.9" % " 2 " }}
        {{ "-7abc" % 2 }}
        {{ "1e1" % 3 }}
        {{ true % 2 }}
        {{ 7 % true }}
        {{ null % 2 }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        1
        -1
        1
        -1
        1
        -1
        1
        -1
        1
        1
        1
        -1
        1
        1
        0
        0
      OUTPUTS
    end

    let(:locals) { { a: 4, b: -5 } }
  end

  ['{{ 5 % 0 }}', '{{ 5 % 0.5 }}', '{{ 5 % "0abc" }}', '{{ 5 % false }}'].each do |source|
    context "with #{source}" do
      it_behaves_like 'render_and_raise' do
        let(:template) { source }
        let(:error) { Twig::Error::Runtime }
        let(:message) { /Modulo by zero/ }
      end
    end
  end

  {
    '{{ "abc" % 2 }}' => 'string % int',
    '{{ 5 % "abc" }}' => 'int % string',
    '{{ 2.5 % "x" }}' => 'float % string',
    '{{ null % "x" }}' => 'null % string',
  }.each do |source, types|
    context "with #{source}" do
      it_behaves_like 'render_and_raise' do
        let(:template) { source }
        let(:error) { Twig::Error::Runtime }
        let(:message) { /Unsupported operand types: #{Regexp.escape(types)}/ }
      end
    end
  end
end
