# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Runtime::Truthiness do
  describe '.true?' do
    it 'is false where PHP casts a value to false' do
      [nil, false, 0, 0.0, -0.0, '', '0', '0'.html_safe, [], {}, Twig::AutoHash.new].each do |value|
        expect(described_class.true?(value)).to be(false), "expected #{value.inspect} to be false"
      end
    end

    it 'is true for anything else, including any object' do
      [true, 1, -1, 0.5, Float::NAN, ' ', '0.0', '00', 'a', [0], { a: nil }, Object.new, (1..0)].each do |value|
        expect(described_class.true?(value)).to be(true), "expected #{value.inspect} to be true"
      end
    end

    it 'is false for an empty filter result' do
      empty = Twig::Runtime::EnumerableHash.from([1]).filter { false }

      expect(described_class.true?(empty)).to be(false)
      expect(described_class.true?(Twig::Runtime::EnumerableHash.from([0]))).to be(true)
    end
  end

  describe '.cast?' do
    it 'is true for Markup, which PHP casts as an object' do
      expect(described_class.cast?('0'.html_safe)).to be(true)
      expect(described_class.cast?(''.html_safe)).to be(true)
    end

    it 'casts other values as true? does, the escape filter output included' do
      expect(described_class.cast?(Twig::Runtime::Escaped.new('0'))).to be(false)
      [nil, false, 0, '', '0', []].each do |value|
        expect(described_class.cast?(value)).to be(false), "expected #{value.inspect} to be false"
      end
      expect(described_class.cast?('a')).to be(true)
    end
  end

  describe 'conditions follow PHP truthiness' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{% if items %}has{% else %}none{% endif %}',
          '{% if "0" %}y{% else %}n{% endif %}{% if {} %}y{% else %}n{% endif %}{% if 0.0 %}y{% else %}n{% endif %}',
          '{% if 0 %}a{% elseif [] %}b{% elseif "0" %}c{% else %}d{% endif %}',
          '{{ [] ? "y" : "n" }}{{ "0" ? "y" : "n" }}{{ [0] ? "y" : "n" }}{{ "0.0" ? "y" : "n" }}',
          '{{ [] ?: "elvis" }}|{{ "0" ?: "z" }}|{{ 5 ?: 6 }}|{{ [1]|first ?: 2 }}',
          '{{ not [] ? "y" : "n" }}{{ not "0" ? "y" : "n" }}{{ not {a: 1} ? "y" : "n" }}',
          '{{ ([] or "0") ? "y" : "n" }}{{ ([1] and {a: 1}) ? "y" : "n" }}{{ ([] xor "0") ? "y" : "n" }}',
          '{% for i in [1, 2, 3] if [] %}{{ i }}{% else %}none{% endfor %}',
          '{% set x %}{{ "0" }}{% endset %}{{ x ? "y" : "n" }}',
          '{{ ([1, 2]|filter(v => v > 5)) ? "y" : "n" }}',
          '{{ undefined ?? "d" }}{{ zero ?? "d" }}{{ zero is defined ? "D" : "U" }}',
        ]
      end
      let(:outputs) do
        ['none', 'nnn', 'd', 'nnyy', 'elvis|z|5|1', 'yyn', 'nyn', 'none', 'n', 'n', 'd0D']
      end
      let(:locals) { { items: [], undefined: nil, zero: 0 } }
    end
  end

  describe 'arrows that filter cast their result like PHP' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ [1, 0, "0", "", [], 2]|filter(v => v)|join(",") }}',
          '{{ {a: 0, b: 1}|filter((v, k) => v)|keys|join }}',
          '{{ [0, "0", 2]|find(v => v) }}',
          '{{ ([0, ""] has some v => v) ? "y" : "n" }}{{ ({a: 0} has some (v, k) => v) ? "y" : "n" }}',
          '{{ ([1, "0"] has every v => v) ? "y" : "n" }}{{ ({a: 1, b: []} has every (v, k) => v) ? "y" : "n" }}',
        ]
      end
      let(:outputs) { ['1,2', 'b', '2', 'nn', 'nn'] }
    end
  end

  describe 'Markup is true in a plain cast but read as its string in a condition' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{% set x %}0{% endset %}{{ [x, "0"|raw, "0"|e, "0"]|filter(v => v)|length }}|' \
          '{{ {a: x}|filter((v, k) => v)|keys|join }}|{{ [0, x]|find(v => v) }}',
          '{% set x %}0{% endset %}{{ ([x] has some v => v) ? "y" : "n" }}' \
          '{{ ({a: x} has some (v, k) => v) ? "y" : "n" }}{{ ([x, "0"|raw] has every v => v) ? "y" : "n" }}' \
          '{{ (["0"|e] has some v => v) ? "y" : "n" }}',
          '{% set x %}0{% endset %}{% for i in [1, 2] if x %}{{ i }}{% else %}none{% endfor %}|' \
          '{% for v in [x, "0"] if v %}[{{ v }}]{% else %}none{% endfor %}',
          '{% set x %}0{% endset %}{{ x ? "y" : "n" }}{{ not x ? "y" : "n" }}{{ (x or false) ? "y" : "n" }}' \
          '{{ x ?: "e" }}{% if x %}y{% else %}n{% endif %}',
        ]
      end
      let(:outputs) { ['2|a|0', 'yyyn', '12|[0]', 'nynen'] }
    end
  end
end
