# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'
require 'active_support/hash_with_indifferent_access'

# The sequence and mapping filters, with expected values from Twig PHP
RSpec.describe Twig::Extension::Core do
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
