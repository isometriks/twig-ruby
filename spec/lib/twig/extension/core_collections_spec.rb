# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'
require 'active_support/hash_with_indifferent_access'

# The sequence and mapping filters, with expected values from Twig PHP
RSpec.describe Twig::Extension::Core do
  describe 'what the filter filter returns' do
    # An array, keeping the keys of a sequence, which works wherever one does
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          {{ [1, 2, 3]|filter(v => v > 1)|json_encode|raw }}
          {{ [1, 2, 3]|filter(v => v > 0)|json_encode|raw }}
          {{ {a: 1, b: 2}|filter(v => v > 1)|json_encode|raw }}
          {{ [1, 2, 3]|filter(v => v > 1)|first }}
          {{ [1, 2, 3]|filter(v => v > 1)|last }}
          {{ [3, 1, 2]|filter(v => v > 0)|sort|join(",") }}
          {{ [1, 2, 3]|filter(v => v > 5) is empty ? "e" : "ne" }}
          {{ ([1, 2, 3]|filter(v => v > 1))[1] }}
          {{ max([1, 2, 3]|filter(v => v > 1)) }}
          {{ [1, 2, 3]|filter(v => v > 1)|reduce((c, v) => c ~ v, "") }}
          {{ [1, 2, 3]|filter(v => v > 1)|reverse|join }}
          {{ [1, 2, 3]|filter(v => v > 1)|merge([4])|join }}
          {{ [1, 2, 3]|filter(v => v > 1)|keys|join }}
          {{ [{"a": 1}, {"a": 2}]|filter(r => r.a > 1)|column("a")|join }}
          {{ [1, 2, 3]|filter(v => v > 1) is sequence ? "s" : "m" }}
          {{ cycle(["a", "b"]|filter(v => true), 1) }}
          {{ cycle(["a", "b", "c"]|filter(v => v != "a"), 1) }}
          {{ max({a: 1, b: 5}|filter(v => v < 5)) }}
          {{ min([3, 1, 2]|filter(v => v > 1)) }}
          {% do [a, b] = [1, 2, 3]|filter(x => x > 1)|filter(x => true) %}{{ a ?? "null" }},{{ b ?? "null" }}
          {% do [a, b] = (1..5)|filter(x => x > 3) %}{{ a ?? "null" }},{{ b ?? "null" }}
          {% do [a, b] = range(1, 5)|filter(x => x > 3) %}{{ a ?? "null" }},{{ b ?? "null" }}
        INPUTS
      end

      let(:outputs) do
        <<~OUTPUTS
          {"1":2,"2":3}
          [1,2,3]
          {"b":2}
          2
          3
          1,2,3
          e
          2
          3
          23
          32
          234
          12
          2
          m
          b
          b
          1
          2
          null,2
          null,null
          null,null
        OUTPUTS
      end
    end

    context 'with an Enumerable' do
      # A Traversable in PHP, which the filters read through iterator_to_array
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ items|filter(v => v > 1)|first }}|{{ items|filter(v => v > 1)|last }}|{{ items|filter(v => v > 1)|join }}
            {{ items|filter(v => v > 1)|reverse|join }}|{{ items|filter(v => v > 1)|slice(0, 1)|join }}
            {{ items|filter(v => v > 1)|sort|join }}|{{ items|filter(v => v > 1)|merge([5])|join }}
            {{ items|filter(v => v > 1)|keys|join }}|{{ items|filter(v => v > 5) is empty ? "e" : "ne" }}
            {{ items|filter(v => v > 1)|batch(1)|length }}|{{ items|filter(v => v > 1)|shuffle|length }}
            {% do [a, b] = items|filter(x => x > 1) %}{{ a }},{{ b }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            2|3|23
            32|2
            23|235
            12|e
            2|2
            2,3
          OUTPUTS
        end

        let(:locals) { { items: [1, 2, 3].each } }
      end

      {
        '{{ cycle(items|filter(v => true), 1) }}' =>
          'The "cycle" function expects an array or "ArrayAccess" as first argument in "template.twig" at line 1.',
        '{{ max(items|filter(v => true)) }}' =>
          'An exception has been thrown during the rendering of a template ("max(): Argument #1 ($value) must be ' \
          'of type array, Twig::Runtime::EnumerableHash given") in "template.twig" at line 1.',
      }.each do |template, message|
        context "with #{template}" do
          it 'raises as for a Traversable' do
            environment = Twig::Environment.new(Twig::Loader::Hash.new({ 'template.twig' => template }))

            expect { environment.load('template.twig').render({ items: [1, 2].each }) }.
              to raise_error(Twig::Error::Runtime, message)
          end
        end
      end
    end
  end

  describe 'the merge filter' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          {% set a = [1, 2] %}{% set b = a|merge([3]) %}{{ a|join(",") }}|{{ b|join(",") }}
          {% set a = [1] %}{% do a|merge([2]) %}{{ a|join }}
          {{ {1: "a"}|merge({1: "b"})|json_encode|raw }}
          {{ {a: 1, 5: 2}|merge([3], {a: 9, b: 1})|json_encode|raw }}
          {{ [1]|merge({a: 2})|json_encode|raw }}
          {{ {"1": "a", "x": "b"}|merge(["c"])|json_encode|raw }}
          {{ {}|merge([])|json_encode|raw }}
          {{ [1]|merge(items)|json_encode|raw }}
        INPUTS
      end

      let(:outputs) do
        <<~OUTPUTS
          1,2|1,2,3
          1
          ["a","b"]
          {"a":9,"0":2,"1":3,"b":1}
          {"0":1,"a":2}
          {"0":"a","x":"b","1":"c"}
          []
          [1,1,2,3]
        OUTPUTS
      end

      let(:locals) { { items: [1, 2, 3].each } }
    end

    context 'with string keys and symbol keys' do
      # PHP has one key for :a and "a", so the later value replaces the first
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{% set x = opts|merge({a: 9}) %}{{ x|json_encode|raw }} {{ x.a }} {{ x|length }}',
            '{{ plain|merge({a: 9}, {c: 3})|json_encode|raw }}',
            '{{ {}|merge({})|json_encode|raw }}',
          ]
        end
        let(:outputs) { ['{"a":9} 9 1', '{"a":9,"b":2,"c":3}', '[]'] }
        let(:locals) { { opts: ActiveSupport::HashWithIndifferentAccess.new(a: 1), plain: { 'a' => 1, 'b' => 2 } } }
      end

      it 'keeps the class of a HashWithIndifferentAccess' do
        merged = described_class.merge(ActiveSupport::HashWithIndifferentAccess.new(a: 1), { a: 9, b: 2 })

        expect(merged).to be_a(ActiveSupport::HashWithIndifferentAccess).and eq('a' => 9, 'b' => 2)
      end
    end

    it "leaves the caller's sequence as it is" do
      list = [1, 2].freeze
      environment = Twig::Environment.new(Twig::Loader::Hash.new({ 'm' => '{{ list|merge(["x"])|join(",") }}' }))

      2.times { expect(environment.load('m').render({ list: })).to eq('1,2,x') }
    end

    {
      'null|merge([1])' => 'null" for argument 1',
      '[1]|merge("x")' => 'string" for argument 2',
      '[1]|merge(true)' => 'bool" for argument 2',
    }.each do |call, message|
      context "with {{ #{call} }}" do
        it_behaves_like 'render_and_raise' do
          let(:template) { "{{ #{call} }}" }
          let(:error) { Twig::Error::Runtime }
          let(:message) do
            "The \"merge\" filter expects a sequence or a mapping, got \"#{message} in \"template.twig\" at line 1."
          end
        end
      end
    end
  end
end
