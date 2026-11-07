# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::ArrowFunction do
  describe 'scoping arguments and assignments to the function' do
    it_behaves_like 'render_and_assert' do
      let(:setup) { "{% set x = 'outer' %}{% set y = 10 %}{% set acc = 'A' %}{% set k = 'K' %}" }
      let(:inputs) do
        [
          "{{ [1, 2]|map(x => x + y)|join(',') }} {{ x }}",
          "{{ [1, 2, 3]|filter(x => x > 1)|join(',') }} {{ x }}",
          '{{ [1, 2, 3]|reduce((acc, x) => acc + x, 0) }} {{ acc }} {{ x }}',
          "{{ [3, 1, 2]|sort((x, y) => x <=> y)|join(',') }} {{ x }} {{ y }}",
          '{{ [1, 2, 3]|find(x => x > 1) }} {{ x }}',
          "{{ {a: 1, b: 2}|map((v, k) => k ~ v)|join(',') }} {{ k }}",
          "{{ ([1, 2] has some x => x > 1) ? 'yes' : 'no' }} {{ x }}",
          "{{ [1, 2]|map(v => (z = v * 2))|join(',') }} {{ z ?? 'no z' }}",
          "{{ [1, 2]|map(v => (y = v))|join(',') }} {{ y }}",
          "{{ [1, 2, 3]|map(v => (n = (n ?? 0) + v))|join(',') }} {{ n ?? 'no n' }}",
          "{{ [[1, 2], [3]]|map(x => x|map(x => x * y)|join('-'))|join(',') }} {{ x }}",
          "{{ [1, 2]|map(x => [10]|map(w => w + x)|first)|join(',') }} {{ w ?? 'no w' }}",
          '{% for i in [1, 2] %}{{ [5]|map(x => x + loop.index)|join }}{% endfor %} {{ x }}',
        ].map { |template| setup + template }
      end
      let(:outputs) do
        [
          '11,12 outer',
          '2,3 outer',
          '6 A outer',
          '1,2,3 outer 10',
          '2 outer',
          'a1,b2 K',
          'yes outer',
          '2,4 no z',
          '1,2 10',
          '1,2,3 no n',
          '10-20,30 outer',
          '11,12 no w',
          '67 outer',
        ]
      end
    end
  end
end
