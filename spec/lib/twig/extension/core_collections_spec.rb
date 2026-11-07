# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'
require 'active_support/hash_with_indifferent_access'

# The sequence and mapping filters, with expected values from Twig PHP
RSpec.describe Twig::Extension::Core do
  # Enumerables of arrays, which PHP reads as a Traversable by position,
  # such as an ArrayIterator of [[1, 2], [3, 4]]
  pair_sequences = { 'a Set' => Set[[1, 2], [3, 4]], 'an Enumerator' => [[1, 2], [3, 4]].each }

  # Yields a key and a value together, as a PHP generator yields 'a' => 1
  let(:yielded) do
    Class.new do
      include Enumerable

      def each
        yield 'a', 1
        yield 'b', 2
      end
    end.new
  end

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

  describe 'a scalar given to a sequence filter or test' do
    # PHP casts it to a string, or to a number for abs and the % of even/odd
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          {{ 123|first }}|{{ 123|last }}|{{ 123|reverse }}|{{ 1.5|first }}|{{ true|first }}|{{ false|first }}
          {{ null|keys|length }}|{{ 5|keys|length }}|{{ "abc"|keys|length }}|{{ items|keys|join }}
          {{ "-3"|abs }}|{{ null|abs }}|{{ true|abs }}|{{ "-2.5"|abs }}|{{ " 3"|abs }}|{{ "-0"|abs }}
          {{ null is even ? 1 : 0 }}{{ "2" is even ? 1 : 0 }}{{ 2.5 is even ? 1 : 0 }}
          {{ "3" is odd ? 1 : 0 }}{{ null is odd ? 1 : 0 }}{{ 3.5 is odd ? 1 : 0 }}
        INPUTS
      end

      let(:outputs) do
        <<~OUTPUTS
          1|3|321|1|1|
          0|0|0|012
          3|0|1|2.5|3|0
          111
          101
        OUTPUTS
      end

      let(:locals) { { items: [1, 2, 3].each } }
    end

    context 'with a float' do
      # PHP's (string) gives 14 significant digits and no ".0" for a whole one
      it_behaves_like 'render_and_assert' do
        let(:input) do
          '{{ 12.0|last }}|{{ 2.0|reverse }}|{{ 12.0|first }}|{{ (0.1 + 0.2)|reverse }}|{{ 1.0e20|last }}|' \
            '{{ (-0.0)|first }}|{{ (1/3)|last }}|{{ 1.5e-7|reverse }}|{{ 123456789012345.0|last }}'
        end
        let(:output) { '2|2|1|3.0|0|-|3|7-E5.1|4' }
      end
    end

    pair_sequences.each do |name, pairs|
      context "with the keys of #{name} of pairs" do
        it_behaves_like 'render_and_assert' do
          let(:inputs) { ['{{ pairs|keys|join(",") }}', '{{ yielded|keys|join(",") }}'] }
          let(:outputs) { ['0,1', 'a,b'] }
          let(:locals) { { pairs:, yielded: } }
        end
      end
    end

    {
      '{{ "abc"|abs }}' => 'abs(): Argument #1 ($num) must be of type int|float, string given',
      '{{ "a" is odd }}' => 'Unsupported operand types: string % int',
    }.each do |template, message|
      context "with #{template}" do
        it_behaves_like 'render_and_raise' do
          let(:template) { template }
          let(:error) { Twig::Error::Runtime }
          let(:message) do
            "An exception has been thrown during the rendering of a template (\"#{message}\") " \
              'in "template.twig" at line 1.'
          end
        end
      end
    end
  end

  describe 'the reduce filter' do
    # The arrow gets the accumulator, the value and the key, or fewer of them
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          {{ [1, 2, 3]|reduce((c, v, k) => c + k, 0) }}
          {{ [1, 2, 3]|reduce((c, v, k) => c ~ k ~ v, "") }}
          {{ [5, 6, 7]|reduce((c, v, k) => c ~ k, "") }}
          {{ [1, 2]|reduce(c => c + 1, 0) }}
          {{ {a: 1, b: 2}|reduce((c, v, k) => c ~ k ~ v, "") }}
          {{ items|reduce((c, v, k) => c ~ k ~ v, "") }}
          {{ []|reduce((c, v) => c + v, 7) }}
        INPUTS
      end

      let(:outputs) { %w[3 011223 012 2 a1b2 011223 7] }
      let(:locals) { { items: [1, 2, 3].each } }
    end

    pair_sequences.each do |name, pairs|
      context "with #{name} of pairs" do
        it_behaves_like 'render_and_assert' do
          let(:inputs) do
            [
              '{{ pairs|reduce((c, v) => c ~ v|join("-") ~ ";", "") }}',
              '{{ pairs|reduce((c, v, k) => c ~ k ~ ":" ~ v|join("-") ~ ";", "") }}',
              '{{ yielded|reduce((c, v, k) => c ~ k ~ v, "") }}',
            ]
          end
          let(:outputs) { ['1-2;3-4;', '0:1-2;1:3-4;', 'a1b2'] }
          let(:locals) { { pairs:, yielded: } }
        end
      end
    end

    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ null|reduce((c, v) => c, 1) }}' }
      let(:error) { Twig::Error::Runtime }
      let(:message) do
        'The "reduce" filter expects a sequence or a mapping, got "null" in "template.twig" at line 1.'
      end
    end
  end

  describe 'the has some and has every tests' do
    # The arrow gets the value and the key of a sequence too
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          {{ [1, 2] has some ((v, k) => k == 1) ? "y" : "n" }}
          {{ [1, 2] has every ((v, k) => k < 1) ? "y" : "n" }}
          {{ [1, 2] has every ((v, k) => k < 5) ? "y" : "n" }}
          {{ [1, 2] has some (v => v > 1) ? "y" : "n" }}
          {{ {"a": 1} has every ((v, k) => k == "a") ? "y" : "n" }}
          {{ items has some ((v, k) => k == 2) ? "y" : "n" }}
          {{ [] has every (v => false) ? "y" : "n" }}
          {{ [1, 2]|filter(v => v > 1) has some ((v, k) => k == 1) ? "y" : "n" }}
        INPUTS
      end

      let(:outputs) { %w[y n y y y y y y] }
      let(:locals) { { items: [1, 2, 3].each } }
    end

    pair_sequences.each do |name, pairs|
      context "with #{name} of pairs" do
        it_behaves_like 'render_and_assert' do
          let(:inputs) do
            [
              '{{ pairs has some (v => v[0] == 3) ? "y" : "n" }}',
              '{{ pairs has every (v => v|length == 2) ? "y" : "n" }}',
              '{{ pairs has some ((v, k) => k == 1) ? "y" : "n" }}',
              '{{ pairs has every ((v, k) => k < 1) ? "y" : "n" }}',
              '{{ yielded has some ((v, k) => k == "b") ? "y" : "n" }}',
            ]
          end
          let(:outputs) { %w[y y y n y] }
          let(:locals) { { pairs:, yielded: } }
        end
      end
    end

    { 'some' => ['"abc"', 'string'], 'every' => %w[null null] }.each do |test, (value, type)|
      context "with {{ #{value} has #{test} v => true }}" do
        it_behaves_like 'render_and_raise' do
          let(:template) { "{{ #{value} has #{test} v => true }}" }
          let(:error) { Twig::Error::Runtime }
          let(:message) do
            "The \"has #{test}\" test expects a sequence or a mapping, got \"#{type}\" " \
              'in "template.twig" at line 1.'
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
