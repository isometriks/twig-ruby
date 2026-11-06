# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Guard do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% guard function importmap %}KO{% else %}OK{% endguard %}
        {% guard function include %}OK{% else %}KO{% endguard %}
        {% guard function importmap %}{{ fake_function()|fake_filter is fake_test }}{% else %}OK{% endguard %}
        {% guard function include %}OK{% else %}{{ fake_function()|fake_filter is fake_test }}{% endguard %}
        {% guard function include %}{% else %}{% block discarded %}{% endblock %}{% endguard %}{{ block('discarded') is defined ? 'KO' : 'OK' }}
        {% guard function include %}{% else %}{% macro m() %}KO{% endmacro %}{% endguard %}{% macro m() %}OK{% endmacro %}{{ _self.m() }}
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
      OUTPUTS
    end

    let(:locals) { { a: true, b: false } }
  end

  it_behaves_like 'render_and_raise' do
    let(:template) { '{% guard foo bar %}{% endguard %}' }
    let(:error) { Twig::Error::Syntax }
    let(:message) do
      'Supported guard types are function, filter and test, "foo" given in "template.twig" at line 1.'
    end
  end

  context 'with an embed in the discarded branch' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          "{% guard function nope %}{% embed 'base' %}{% block b %}{{ nope() }}{% endblock %}{% endembed %}" \
          '{% else %}fallback{% endguard %}',
          "{% guard filter nope %}{% embed 'base' %}{% block b %}{{ 1|nope }}{% endblock %}{% endembed %}" \
          '{% else %}fallback{% endguard %}',
          "{% guard function include %}{% embed 'base' %}{% block b %}OK{% endblock %}{% endembed %}" \
          '{% else %}{% embed \'base\' %}{% block b %}{{ nope() }}{% endblock %}{% endembed %}{% endguard %}',
        ]
      end

      let(:outputs) { ['fallback', 'fallback', '[OK]'] }
      let(:templates) { { base: '[{% block b %}{% endblock %}]' } }
    end

    it 'still rejects an unknown function in an embed after the guard' do
      environment = Twig::Environment.new(Twig::Loader::Hash.new({
        'base' => '[{% block b %}{% endblock %}]',
        'index' => "{% guard function nope %}{% embed 'base' %}{% block b %}{{ nope() }}{% endblock %}" \
                   "{% endembed %}{% else %}fallback{% endguard %}{% embed 'base' %}{% block b %}{{ nope() }}" \
                   '{% endblock %}{% endembed %}',
      }))

      expect { environment.load('index') }.
        to raise_error(Twig::Error::Syntax, 'Unknown "nope" function in "index" at line 1.')
    end
  end
end
