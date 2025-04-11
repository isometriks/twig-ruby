# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Test::Defined do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ a is defined ? 'OK' : 'KO' }}
        {{ b is defined ? 'OK' : 'KO' }}
        {{ c is defined ? 'KO' : 'OK' }}
        {{ @var is defined ? 'OK' : 'KO' }}
        {{ @other is defined ? 'KO' : 'OK' }}
        {{ _context is defined ? 'OK' : 'KO' }}
        {{ _self is defined ? 'OK' : 'KO' }}
        {{ _charset is defined ? 'OK' : 'KO' }}
        {{ "test" is defined ? 'OK' : 'KO' }}
        {{ ["hello"] is defined ? 'OK' : 'KO' }}
        {{ {hello: "world"} is defined ? 'OK' : 'KO' }}
        {{ block("hey") is defined ? 'KO' : 'OK' }}
        {% block hey "" %}{{ block("hey") is defined ? 'OK' : 'KO' }}
        {% extends "parent.twig" %}{% block content %}{{ block("hey") is defined ? 'OK' : 'KO' }}{% endblock %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        OK
        OK
        OK
        OK
        OK
        OK
        OK
        OK
        OK
        OK
        OK
        OK
        OK
        OK
      OUTPUTS
    end

    let(:locals) do
      {
        a: nil,
        b: true,
      }
    end

    let(:templates) do
      {
        'parent.twig': '{% block content ""%}{% block hey "" %}',
      }
    end

    let(:call_context) do
      Class.new do
        def initialize
          @var = true
        end
      end.new
    end
  end
end
