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
        {% extends "parent" %}{% block content "Hello World" %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello and Goodbye World!
        Hello and Goodbye World!
        --Hello World--
      OUTPUTS
    end

    let(:locals) { { template: 'base' } }
    let(:templates) do
      {
        base: '{% block original %}Goodbye{% endblock %} World!',
        intermediate: '{% extends "base" %}',
        parent: "{% set content = block('content') %}--{{ content }}--",
      }
    end
  end

  it_behaves_like 'render_and_raise' do
    let(:template) { '{% macro foo() %}{% extends "whatever.twig" %}{% endmacro %}' }
    let(:error) { Twig::Error::Syntax }
    let(:message) { /cannot use "extend" in a macro/i }
  end
  it_behaves_like 'render_and_raise' do
    let(:template) { '{% if true %}{% extends "whatever.twig" %}{% endif %}' }
    let(:error) { Twig::Error::Syntax }
    let(:message) { 'The "extends" tag can only be used at the root of a template in "template.twig" at line 1.' }
  end

  it_behaves_like 'render_and_raise' do
    let(:template) { "{% extends 'a.twig' %}\n{% extends 'b.twig' %}" }
    let(:error) { Twig::Error::Syntax }
    let(:message) { 'Multiple extends tags are forbidden in "template.twig" at line 2.' }
  end
end
