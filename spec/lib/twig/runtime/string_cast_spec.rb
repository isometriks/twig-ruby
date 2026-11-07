# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Runtime::StringCast do
  describe 'a float prints as PHP prints it' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 1.0 }}|{{ 1e3 }}|{{ 0.1 + 0.2 }}|{{ 1 / 3 }}|{{ 7 / 2 }}|{{ -0.0 }}|{{ 4 ** 0.5 }}',
          '{{ 1e15 }}|{{ 1e14 }}|{{ 99999999999999.99 }}|{{ 1.5e-7 }}|{{ 0.0001 }}|{{ 0.00001 }}|{{ -1.5e300 }}',
          '{{ 123456789.12345678 }}|{{ 100000000000000000000 }}|{{ 9223372036854775807 + 1 }}|{{ 2 ** 64 }}',
        ]
      end
      let(:outputs) do
        [
          '1|1000|0.3|0.33333333333333|3.5|-0|2',
          '1.0E+15|1.0E+14|1.0E+14|1.5E-7|0.0001|1.0E-5|-1.5E+300',
          '123456789.12346|1.0E+20|9.2233720368548E+18|1.844674407371E+19',
        ]
      end
    end
  end

  describe 'INF and NAN print as PHP prints them' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 0 ** -1 }}|{{ -0 ** -1 }}|{{ (-8) ** 0.5 }}|{{ 1e308 * 10 }}',
        ]
      end
      let(:outputs) do
        [
          'INF|-INF|NAN|INF',
        ]
      end
    end
  end

  describe 'a float becomes a string as PHP casts it' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 1.0 ~ "" }}|{{ (0.1 + 0.2) ~ "!" }}|{{ "#{2.0}" }}|{{ "a#{1e20}b" }}|{{ 1.0|e }}|{{ 1.0|e("js") }}',
          '{% set x = 2.0 %}{{ x }}|{{ x|raw }}|{% autoescape false %}{{ x }}{% endautoescape %}',
          '{{ [1.0, 0.1 + 0.2, 2.5]|join(",") }}',
          '{{ 1.0 in "1" ? "y" : "n" }}|{{ 1.0 in "1.0" ? "y" : "n" }}|{{ 1.5 < "1.5a" ? "y" : "n" }}',
        ]
      end
      let(:outputs) do
        [
          '1|0.3!|2|a1.0E+20b|1|1',
          '2|2|2',
          '1,0.3,2.5',
          'y|y|y',
        ]
      end
    end
  end

  describe 'round gives what PHP prints and uses' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 2.5|round }}|{{ -2.5|round }}|{{ -0.04|round(1) }}|{{ 0.04|round(1, "floor") }}|{{ 1.955|round(2) }}',
          '{{ 21.3|round(-1) }}|{{ 21.3|round(-1, "ceil") }}|{{ 1234.567|round(2, "floor") }}|{{ null|round }}',
          '{{ 1e20|round }}|{{ (0 ** -1)|round }}|{{ {3: "a"}[2.5|round] }}|{{ [10, 20][1.5] }}',
          '{{ range(1, 2.5|round)|join }}|{{ "abc"|slice(0, 1.5|round) }}|{{ [1, 2, 3]|batch(1.5|round)|length }}',
          '{% for i in (3.4|round + 1)..5 %}o{% endfor %}|{{ "%s"|format(2.5|round) }}|{{ (2.5|round)|length }}',
          '{{ (2.5|round) matches "/^3$/" ? 1 : 0 }}|{{ (2.5|round)|split("")|join("-") }}|{{ (2.5|round)|striptags }}',
        ]
      end
      let(:outputs) do
        [
          '3|-3|-0|0|1.96',
          '20|30|1234.56|0',
          '1.0E+20|INF|a|20',
          '123|ab|2',
          'oo|3|1',
          '1|3|3',
        ]
      end
    end
  end

  describe 'a float key' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) { ['{{ rates[1.5] }}|{{ rates[x] }}|{{ rates[1.9] }}|{{ items[1.9] }}'] }
      let(:outputs) { ['a|a|b|20'] }
      let(:locals) { { rates: { 1.5 => 'a', 1 => 'b' }, x: 1.5, items: [10, 20] } }
    end
  end

  describe 'json_encode and number_format write a float as PHP does' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 3.0|json_encode }}|{{ (2.5|round)|json_encode }}|{{ {a: 1.0, b: [2.0, 0.5], c: 1e16}|json_encode|raw }}',
          '{{ [0.4|round, 0.0, -0.0, -0.04|round(1), {(2.5|round): 1.5}]|json_encode|raw }}',
          '{{ 1.0|number_format }}|{{ 1234.5|number_format(2) }}|{{ (2.5|round)|number_format(1) }}',
        ]
      end
      let(:outputs) do
        [
          '3|3|{"a":1,"b":[2,0.5],"c":10000000000000000}',
          '[0,0,-0,-0,{"3":1.5}]',
          '1|1,234.50|3.0',
        ]
      end
    end
  end

  describe 'a float printed into a decorated buffer' do
    it_behaves_like 'render_and_assert' do
      let(:decorated) do
        Class.new do
          def initialize
            @parts = []
          end

          def safe_append=(value)
            @parts << value
          end

          def to_s
            @parts.map { |part| "[#{part}]" }.join
          end
        end.new
      end
      let(:output_buffer) { Twig::OutputBuffer.new(decorated) }
      let(:inputs) { ['{{ 1.0 }}{{ 0.1 + 0.2 }}'] }
      let(:outputs) { ['[1][0.3]'] }
    end
  end

  describe '.float' do
    it 'formats a float as PHP does' do
      expect(described_class.float(1.0)).to eq('1')
      expect(described_class.float(-1.5e-10)).to eq('-1.5E-10')
      expect(described_class.float(1.25e100)).to eq('1.25E+100')
      expect(described_class.float(12_345_678_901_234.0)).to eq('12345678901234')
      expect(described_class.float(-Float::INFINITY)).to eq('-INF')
    end
  end

  describe 'round' do
    it 'returns an Integer for no decimal places while PHP\'s int holds it' do
      expect(Twig::Extension::Core.round(2.5)).to eql(3)
      expect(Twig::Extension::Core.round(21.3, precision: -1, method: :ceil)).to eql(30)
      expect(Twig::Extension::Core.round(-0.4)).to eql(0)
      expect(Twig::Extension::Core.round(1e20)).to eql(1e20)
    end

    it 'returns a Float for decimal places, keeping a negative zero' do
      expect(Twig::Extension::Core.round(2.25, precision: 1)).to eql(2.3)
      expect(Twig::Extension::Core.round(-0.04, precision: 1).to_s).to eq('-0.0')
      expect(Twig::Extension::Core.round(-0.04, precision: 1, method: :ceil).to_s).to eq('-0.0')
    end
  end
end
