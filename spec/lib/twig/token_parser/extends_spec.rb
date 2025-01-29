# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Extends do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% extends "base" %}{% block original %}Hello{% endblock %}
        {% extends template %}{% block original %}Hello{% endblock %}
        {% extends "base" %}{% block original %}Hello and {{ parent() }}{% endblock %}
        {% extends "intermediate" %}{% block original %}Hello and {{ parent() }}{% endblock %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello and Goodbye World!
        Hello and Goodbye World!
      OUTPUTS
    end

    let(:locals) { { template: 'base' } }
    let(:templates) do
      {
        base: '{% block original %}Goodbye{% endblock %} World!',
        intermediate: '{% extends "base" %}',
      }
    end
  end
end
