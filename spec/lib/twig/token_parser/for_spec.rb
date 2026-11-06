# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::For do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% for i in numbers %}{{ i }}{% endfor %}
        {% for i in empty %}{{ i }}{% else %}empty{% endfor %}
        {% for x in [0, 1] %}{% for y in [0, 1] %}{{ x }}-{{ y }},{% endfor %}{% endfor %}
        {% for i in 0..3 %}{{ loop.cycle('even', 'odd') }}-{% endfor %}
        {% for i in [0, 1, 2] %}{{ loop.index0 }}{% endfor %}
        {% for i in [0, 1, 2] %}{{ loop.index }}{% endfor %}
        {% for x in [0, 1] %}{{ loop.index0 }}-{% for y in [0, 1, 2] %}{{ loop.index0 }}{% endfor %}{% endfor %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        123
        empty
        0-0,0-1,1-0,1-1,
        even-odd-even-odd-
        012
        123
        0-0121-012
      OUTPUTS
    end

    let(:locals) { { numbers: [1, 2, 3], empty: [] } }
  end
end

RSpec.describe 'The for loop else flag' do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      [
        "{% set _iterated = 'mine' %}{% for i in [1] %}{% else %}{% endfor %}{{ _iterated }}",
        "{% for i in [] %}{% else %}{{ _context|keys|join(',') }}{% endfor %}",
        '{% for i in [1, 2] %}[{% for j in [] %}{% else %}e{% endfor %}{% for k in [i] %}{{ k }}' \
        '{% else %}E{% endfor %}]{% else %}none{% endfor %}',
        '{% for i in [] %}{% else %}{% for j in [1] %}{{ j }}{% else %}E{% endfor %}{% endfor %}',
        '{% for i in [1] %}{% for j in [] %}{% else %}inner{% endfor %}{% else %}outer{% endfor %}',
        '{% for i in [1, 2, 3] if i > 5 %}{{ i }}{% else %}none{% endfor %}|' \
        '{% for i in [1, 2, 3] if i > 2 %}{{ i }}{% else %}none{% endfor %}',
        '{% for i in [{n: "a", c: [{n: "b", c: [1]}]}] %}{{ i.n }}({% for c in i.c %}{{ loop.parent.loop.index }}' \
        '{% else %}E{% endfor %}{% if i.n == "a" %}{{ loop(i.c) }}{% endif %}){% else %}E{% endfor %}',
        "{% for i in [1, 1, 2] %}{% if loop.changed(i) %}{{ i }}{% endif %}{{ loop.cycle('a', 'b') }}" \
        '{% else %}E{% endfor %}',
        '{% macro m(xs) %}{% for x in xs %}{{ x }}{% else %}empty{% endfor %}{% endmacro %}' \
        '{{ _self.m([]) }}{{ _self.m([1]) }}',
        '{% block b %}{% for x in [] %}{{ x }}{% else %}empty{% endfor %}{% endblock %}',
      ]
    end

    let(:outputs) do
      ['mine', 'loop', '[e1][e2]', '1', 'inner', 'none|3', 'a(1b(1))', '1ab2a', 'empty1', 'empty']
    end
  end
end
