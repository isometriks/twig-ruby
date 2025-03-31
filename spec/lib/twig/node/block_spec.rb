# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Block do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% block test %}Hello World!{% endblock %}
        {% block test %}Hello World!{% endblock test %}
        {% extends 'second.twig' %}{% block test %}{{ parent() }}{% endblock %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello Nobody!
      OUTPUTS
    end

    let(:templates) do
      {
        'base.twig': '{% block test %}Hello Nobody!{% endblock %}',
        'second.twig': '{% extends "base.twig" %}{% block test %}{{ parent() }}{% endblock %}',
      }
    end
  end
end
