# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Include do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        Hello {% include "include" %}
        Hello {% include "include" only %}
        Hello {% include template %}
        Hello {% include "deep" %}
        Hello-{% include "missing" ignore missing %}-World!
        {% include "vars" with { var: "Hello World!" } %}
        {% include "vars" ignore missing with { var: "Hello World!" } %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        Hello--World!
        Hello World!
        Hello World!
      OUTPUTS
    end

    let(:locals) { { template: 'include' } }

    let(:templates) do
      {
        include: 'World!',
        deep: '{% include "include" %}',
        vars: '{{ var }}',
      }
    end
  end
end

RSpec.describe 'Including a template with an empty sequence of variables' do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      [
        '{{ include("vars", []) }}',
        '{% include "vars" with [] %}',
        '{% include "vars" with [] only %}',
        '{% embed "vars" with [] %}{% endembed %}',
        '{% embed "vars" with [] only %}{% endembed %}',
      ]
    end

    let(:outputs) { %w[Hello Hello none Hello none] }
    let(:locals) { { var: 'Hello' } }
    let(:templates) { { vars: '{{ var ?? "none" }}' } }
  end
end

# Like PHP's CoreExtension::merge and toArray, any iterable can be the variables
RSpec.describe 'Including a template with an iterable as its variables' do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      [
        "{% include 'vars' with ['x'] %}",
        "{% include 'vars' with ['x'] only %}",
        "{{ include('vars', ['x']) }}",
        "{{ include('vars', ['x'], with_context = false) }}",
        "{% embed 'vars' with ['x'] %}{% endembed %}",
        "{% embed 'vars' with ['x'] only %}{% endembed %}",
        "{% include 'vars' with {var: 2}|filter(v => true) %}",
        "{% include 'vars' with {var: 2}|filter(v => true) only %}",
        "{{ include('vars', {var: 2}|filter(v => true)) }}",
        "{% embed 'vars' with {var: 2}|filter(v => true) %}{% endembed %}",
        "{% include 'vars' with 1..2 %}",
        "{% include 'vars' with [5, 6]|map(x => x) %}",
        "{% include 'missing' ignore missing with ['x'] %}{% include 'vars' ignore missing with ['x'] %}",
      ]
    end

    let(:outputs) { %w[[1] [-] [1] [-] [1] [-] [2] [2] [2] [2] [1] [1] [1]] }
    let(:locals) { { var: 1 } }
    let(:templates) { { vars: "[{{ var|default('-') }}]" } }
  end
end

RSpec.describe 'Including a template with a value that is not iterable as its variables' do
  {
    "{% include 'vars' with 'str' %}" =>
      'The "merge" filter expects a sequence or a mapping, got "string" for argument 2',
    "{% embed 'vars' with 'str' %}{% endembed %}" =>
      'The "merge" filter expects a sequence or a mapping, got "string" for argument 2',
    "{% include 'vars' with null %}" =>
      'The "merge" filter expects a sequence or a mapping, got "null" for argument 2',
    "{% include 'vars' with true %}" =>
      'The "merge" filter expects a sequence or a mapping, got "bool" for argument 2',
    "{{ include('vars', 'str') }}" =>
      'An exception has been thrown during the rendering of a template ' \
      '("array_merge(): Argument #2 must be of type array, string given")',
  }.each do |source, message|
    context "with #{source}" do
      it_behaves_like 'render_and_raise' do
        let(:loader) { Twig::Loader::Hash.new({ 'template.twig' => source, 'vars' => '{{ var }}' }) }
        let(:error) { Twig::Error::Runtime }
        let(:message) { %(#{message} in "template.twig" at line 1.) }
      end
    end
  end
end
