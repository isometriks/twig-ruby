# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Runtime::Spread do
  describe 'spreading a filter result into a sequence spreads its values' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ [...(list|filter(x => x > 1))]|json_encode|raw }}',
          '{{ [0, ...(list|filter(x => x > 1)), 9]|json_encode|raw }}',
          '{{ [...(items|filter(x => x > 1))]|json_encode|raw }}',
        ]
      end
      let(:outputs) { ['[2,3]', '[0,2,3,9]', '[2,3]'] }
      let(:locals) { { list: [1, 2, 3], items: (1..3).each } }
    end
  end

  describe 'spreading a mapping into a sequence keeps its string keys' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ [...map]|json_encode|raw }}',
          '{{ [...(map|filter(x => true))]|json_encode|raw }}',
          '{{ [0, ...{a: 1}, 2, ...{a: 3, "1": "x"}]|json_encode|raw }}',
          '{{ [...{"1": "a"}, ...{"1": "b"}]|json_encode|raw }}',
          '{{ [1, ...[2], ...(1..2)]|json_encode|raw }}',
        ]
      end
      let(:outputs) do
        [
          '{"a":1,"b":2,"c":3}',
          '{"a":1,"b":2,"c":3}',
          '{"0":0,"a":3,"1":2,"2":"x"}',
          '["a","b"]',
          '[1,2,1,2]',
        ]
      end
      let(:locals) { { map: { 'a' => 1, 'b' => 2, 'c' => 3 } } }
    end
  end

  describe 'spreading into a mapping keeps string keys and renumbers integer keys' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ {...(map|filter(x => x > 1))}|json_encode|raw }}',
          '{{ {z: 0, ...(map|filter(x => x > 1))}|json_encode|raw }}',
          '{{ {...(list|filter(x => x > 1))}|json_encode|raw }}',
          '{{ {5: "x", ...(list|filter(x => x > 1))}|json_encode|raw }}',
          '{{ {...{0: "a"}, ...{0: "b"}}|json_encode|raw }}',
          '{{ {5: "x", ...{0: "a"}, 2: "y", ...[7]}|json_encode|raw }}',
          '{{ {...{a: 1}, ...{a: 2}, b: 3}|json_encode|raw }}',
          '{{ {...null}|json_encode|raw }}',
          '{{ {...{"1": "a"}, ...{"1": "b"}}|json_encode|raw }}',
          '{{ {5: "x", ...{"0": "a"}}|json_encode|raw }}',
          '{{ {"5": "x", ...[1]}|json_encode|raw }}',
          '{{ {"-5": "x", ...["a"], 3: "y", ...["b"]}|json_encode|raw }}',
        ]
      end
      let(:outputs) do
        [
          '{"b":2,"c":3}',
          '{"z":0,"b":2,"c":3}',
          '{"0":2,"1":3}',
          '{"5":"x","6":2,"7":3}',
          '{"0":"a","1":"b"}',
          '{"5":"x","6":"a","2":"y","7":7}',
          '{"a":2,"b":3}',
          '{}',
          '{"0":"a","1":"b"}',
          '{"5":"x","6":"a"}',
          '{"5":"x","6":1}',
          '{"-5":"x","-4":"a","3":"y","4":"b"}',
        ]
      end
      let(:locals) { { list: [1, 2, 3], map: { 'a' => 1, 'b' => 2, 'c' => 3 } } }
    end
  end

  describe 'spreading a filter result into a macro' do
    it_behaves_like 'render_and_assert' do
      let(:macro) do
        '{% macro m(a = null, b = null, c = null) %}[{{ a ?? "null" }}|{{ b ?? "null" }}|{{ c ?? "null" }}]' \
          '{% endmacro %}'
      end
      let(:inputs) do
        [
          "#{macro}{{ _self.m(...(list|filter(x => x > 1))) }}",
          "#{macro}{{ _self.m(9, ...(list|filter(x => x > 1))) }}",
          "#{macro}{{ _self.m(...({c: 1, a: 2, z: 0}|filter(x => x > 0))) }}",
        ]
      end
      let(:outputs) { ['[2|3|null]', '[9|2|3]', '[2|null|1]'] }
      let(:locals) { { list: [1, 2, 3] } }
    end
  end

  context 'when spreading something that is not a mapping into a mapping' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ {...5} }}' }
      let(:error) { Twig::Error::Runtime }
      let(:message) { /no implicit conversion of Integer into Hash/ }
    end
  end
end
