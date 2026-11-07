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

  describe '#arguments' do
    it 'splits a value into positional and named arguments as PHP unpacks it' do
      expect(described_class.new({ 0 => 'a', '1' => 'b', c: 'c', 'd' => 'd' }).arguments).
        to eq([%w[a b], { 'c' => 'c', 'd' => 'd' }])
      expect(described_class.new(1..2).arguments).to eq([[1, 2], {}])
      expect(described_class.new(Set[1, 2]).arguments).to eq([[1, 2], {}])
      expect { described_class.new({ 'a' => 1, 0 => 2 }).arguments }.
        to raise_error(ArgumentError, 'Cannot use positional argument after named argument during unpacking')
      expect { described_class.new({ 1.5 => 1 }).arguments }.
        to raise_error(TypeError, 'Keys must be of type int|string during argument unpacking')
      expect { described_class.new(nil).arguments }.
        to raise_error(TypeError, 'Only arrays and Traversables can be unpacked')
    end
  end

  describe 'spreading any iterable into a mapping' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ {...(1..3)}|join(",") }}',
          '{{ {5: "x", ...(1..2)}|keys|join(",") }}',
          '{{ {...items}|join(",") }}',
        ]
      end
      let(:outputs) { ['1,2,3', '5,6,7', '1,2'] }
      let(:locals) { { items: [1, 2].each } }
    end
  end

  describe 'spreading into a function, filter or method call unpacks as PHP does' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ max(...range(1, 3)) }}',
          '{{ max(...(list|filter(v => v < 5))) }}',
          '{{ max(...items) }}',
          '{{ o.m(...range(1, 2)) }}',
          '{{ o.m(...(list|filter(v => v < 5))) }}',
          '{{ o.m(...items) }}',
          '{{ o.m(...{0: "x", 1: "y"}) }}',
          '{{ o.m(...{"0": "x", "1": "y"}) }}',
          '{{ o.m(...{0: "y", a: "x"}) }}',
          '{{ o.m(1, ...{a: "x"}, ...{b: "y"}) }}',
          '{{ o.m(...{a: 1}, ...{a: 2}) }}',
          '{{ attribute(o, "m", [1, 2]) }}',
          '{{ attribute(o, "m", {a: 1}) }}',
          '{{ "a"|replace(...{from: {a: "b"}}) }}',
          '{{ [1, 2]|join(...{0: "-"}) }}',
          '{{ [1, 2]|join(...["-"]) }}',
          '{% macro m(a, b) %}{{ a }}-{{ b }}{% endmacro %}{{ _self.m(...{"0": 2, "b": 1}) }}',
          '{% macro m(a, b) %}{{ a }}-{{ b }}{% endmacro %}{{ _self.m(...items) }}',
        ]
      end
      let(:outputs) do
        %w[3 2 2 1,2 1,2 1,2 x,y x,y y,a=x 1,a=x,b=y a=2 1,2 a=1 b 1-2 1-2 2-1 1-2]
      end
      let(:locals) do
        {
          list: [1, 5, 2],
          items: [1, 2].each,
          o: Class.new do
            def m(*args, **kwargs)
              [*args, *kwargs.map { |k, v| "#{k}=#{v}" }].join(',')
            end
          end.new,
        }
      end
    end
  end

  {
    '{{ o.m(...{a: "x", 0: "y"}) }}' => 'Cannot use positional argument after named argument during unpacking',
    '{{ [1, 2]|join(...{and_glue: "+", 0: "-"}) }}' =>
      'Cannot use positional argument after named argument during unpacking',
    '{{ o.m(...nothing) }}' => 'Only arrays and Traversables can be unpacked',
    '{{ max(...nothing) }}' => 'Only arrays and Traversables can be unpacked',
    '{{ max(...number) }}' => 'Only arrays and Traversables can be unpacked',
    '{{ o.m(...text) }}' => 'Only arrays and Traversables can be unpacked',
    '{% macro m(a) %}{% endmacro %}{{ _self.m(...nothing) }}' => 'Only arrays and Traversables can be unpacked',
    '{{ {...nothing}|length }}' => 'Only arrays and Traversables can be unpacked',
    '{{ [...nothing]|length }}' => 'Only arrays and Traversables can be unpacked',
    '{{ {...null}|length }}' => 'Only arrays and Traversables can be unpacked',
    '{{ o.m(b: 2, 3) }}' => 'Cannot use positional argument after named argument during unpacking',
    '{{ [1, 2, 3]|join(...["-"], ...{glue: "+"}) }}' => 'Named parameter $glue overwrites previous argument',
    '{{ 1234.5|number_format(...[2], ...{decimal: 1}) }}' => 'Named parameter $decimal overwrites previous argument',
    '{{ "a"|replace(...{nope: 1}) }}' => 'Unknown named parameter $nope',
    '{{ "a"|replace({a: "b"}, ...{from: 1}) }}' => 'Named parameter $from overwrites previous argument',
  }.each do |template, message|
    context "when unpacking #{template}" do
      it 'raises what PHP raises' do
        loader = Twig::Loader::Hash.new({ 'index' => template })
        environment = Twig::Environment.new(loader)
        o = Class.new { def m(*); end }.new

        expect { environment.load('index').render({ o:, nothing: nil, number: 5, text: 'ab' }) }.
          to raise_error(
            Twig::Error::Runtime,
            "An exception has been thrown during the rendering of a template (\"#{message}\") in \"index\" at line 1."
          )
      end
    end
  end

  {
    '{{ "a" is same as(...["a"]) }}' => 'same as',
    '{{ 4 is divisible by(...[2]) }}' => 'divisible by',
  }.each do |template, test|
    context "when spreading into the #{test} test" do
      it_behaves_like 'render_and_raise' do
        let(:template) { template }
        let(:error) { Twig::Error::Syntax }
        let(:message) { 'syntax error, unexpected token "..." in "template.twig" at line 1' }
      end
    end
  end

  context 'when spreading into the constant test' do
    it_behaves_like 'render_and_assert' do
      let(:input) { "{{ constant('Twig::VERSION') is constant(...['Twig::VERSION']) ? 'y' : 'n' }}" }
      let(:output) { 'y' }
    end
  end

  context 'when spreading something that is not a mapping into a mapping' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ {...5} }}' }
      let(:error) { Twig::Error::Runtime }
      let(:message) { /Only arrays and Traversables can be unpacked/ }
    end
  end
end
