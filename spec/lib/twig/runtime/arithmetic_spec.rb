# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'
require 'bigdecimal'

RSpec.describe Twig::Runtime::Arithmetic do
  describe '+ - and * cast numeric strings, null and booleans' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 2 * "3" }}|{{ null + 1 }}|{{ "1.5" + 1 }}|{{ " 2 " * 3 }}',
          '{{ true + true }}|{{ null - null }}|{{ 1 - true }}|{{ "7abc" + 1 }}',
          '{{ [1, 2, 3]|reduce((c, v) => c + v) }}|{{ "1" + "2" }}',
          '{{ -"3" }}|{{ +"3" }}|{{ -null }}|{{ -true }}|{{ -a }}|{{ -"2" ** 2 }}',
        ]
      end
      let(:outputs) do
        [
          '6|1|2.5|6',
          '2|0|0|8',
          '6|3',
          '-3|3|0|-1|-4|-4',
        ]
      end
      let(:locals) { { a: 4 } }
    end
  end

  describe '/ and // cast numeric strings, null and booleans' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ "10" / 4 }}|{{ "6" / "3" }}|{{ null / 1 }}|{{ true / 2 }}',
          '{{ "7" // "2" }}|{{ null // 2 }}|{{ 7.5 // 2 }}|{{ -7 // 2 }}|{{ 7 // -2.5 }}',
        ]
      end
      let(:outputs) do
        [
          '2.5|2|0|0.5',
          '3|0|3|-4|-3',
        ]
      end
    end
  end

  describe '/ and // keep the precision of a BigDecimal or a Rational' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ (total / 3).class }}|{{ (big / 2 * 2) == big ? "same" : "changed" }}|{{ (big / 1)|number_format(2) }}',
          '{{ third / 2 }}|{{ 1 / third }}|{{ big // 2 }}|{{ (total / "4")|number_format(2) }}',
        ]
      end
      let(:outputs) do
        [
          'BigDecimal|same|12,345,678,901,234,567.89',
          '1/6|3/1|6172839450617283|25.00',
        ]
      end
      let(:locals) do
        { total: BigDecimal('100'), big: BigDecimal('12345678901234567.89'), third: Rational(1, 3) }
      end
    end
  end

  describe '** casts numeric strings, null and booleans' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ "2" ** "3" }}|{{ null ** 2 }}|{{ 2 ** null }}|{{ "2" ** -1 }}|{{ (-2) ** 63 }}',
        ]
      end
      let(:outputs) do
        [
          '8|0|1|0.5|-9223372036854775808',
        ]
      end
    end
  end

  describe 'integers too big for PHP' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 9223372036854775807 // 1 }}|{{ -9223372036854775807 - 1 }}',
        ]
      end
      let(:outputs) do
        [
          '-9223372036854775808|-9223372036854775808',
        ]
      end
    end
  end

  describe '% casts floats and numeric strings too big for an integer as PHP does' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 1e20 % 7 }}|{{ 1e19 % 7 }}|{{ "1e20" % 7 }}|{{ "9999999999999999999" % 7 }}',
        ]
      end
      let(:outputs) do
        [
          '6|-6|0|0',
        ]
      end
    end
  end

  describe 'bitwise operators cast like PHP and combine strings byte by byte' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 5 b-and 3 == 1 }}|{{ "12" b-or 1 }}|{{ 1.5 b-or 0 }}|{{ null b-xor 3 }}|{{ true b-or false }}',
          '{{ 1e20 b-and 255 }}|{{ "1e20" b-and 255 }}|{{ "12" b-or "3" }}|{{ "abc" b-or "de" }}|{{ "ab" b-and "c" }}',
        ]
      end
      let(:outputs) do
        [
          '0|13|1|3|1',
          '0|255|32|egc|a',
        ]
      end
    end
  end

  describe 'errors' do
    {
      '{{ 1 / 0 }}' => 'Division by zero',
      '{{ 7.0 / 0 }}' => 'Division by zero',
      '{{ 7 / 0.0 }}' => 'Division by zero',
      '{{ 7 // 0 }}' => 'Division by zero',
      '{{ 1 / null }}' => 'Division by zero',
      '{{ 5.5 % 0 }}' => 'Modulo by zero',
      '{{ "abc" + 1 }}' => 'Unsupported operand types: string + int',
      '{{ 1 - "abc" }}' => 'Unsupported operand types: int - string',
      '{{ "a" * "b" }}' => 'Unsupported operand types: string * string',
      '{{ "" + 1.5 }}' => 'Unsupported operand types: string + float',
      '{{ "abc" + true }}' => 'Unsupported operand types: string + bool',
      '{{ null + "abc" }}' => 'Unsupported operand types: null + string',
      '{{ -"abc" }}' => 'Unsupported operand types: string * int',
      '{{ "abc" / 2 }}' => 'Unsupported operand types: string / int',
      '{{ "abc" ** 2 }}' => 'Unsupported operand types: string ** int',
      '{{ 7 % "abc" }}' => 'Unsupported operand types: int % string',
      '{{ "abc" b-and 1 }}' => 'Unsupported operand types: string & int',
    }.each do |source, reason|
      context "with #{source}" do
        it_behaves_like 'render_and_raise' do
          let(:template) { source }
          let(:error) { Twig::Error::Runtime }
          let(:message) { /a template \("#{Regexp.escape(reason)}"\) in "template.twig" at line 1\.\z/ }
        end
      end
    end
  end

  describe '.add' do
    it 'gives a Float for an integer result PHP can\'t hold' do
      expect(described_class.add((2**63) - 1, 1)).to eql(9.223372036854776e18)
      expect(described_class.multiply((2**63) - 1, 2)).to eql(1.8446744073709552e19)
      expect(described_class.subtract(-(2**63), 1)).to eql(-9.223372036854776e18)
    end

    it 'uses Ruby\'s operator for other objects' do
      expect(described_class.add(Time.at(0).utc, 60)).to eq(Time.at(60).utc)
      expect(described_class.subtract(Date.new(2024, 1, 2), 1)).to eq(Date.new(2024, 1, 1))
    end
  end
end
