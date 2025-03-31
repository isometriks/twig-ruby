# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Use do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% extends "base.twig" %}{% use "blocks.twig" %}
        {% extends "base.twig" %}{% use "blocks.twig" with greeting as message %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello Earth!
      OUTPUTS
    end

    let(:templates) do
      {
        'base.twig': '{% block message %}Goodbye World!{% endblock %}',
        'blocks.twig': '{% block message %}Hello World!{% endblock %}{% block greeting %}Hello Earth!{% endblock %}',
      }
    end
  end
end
