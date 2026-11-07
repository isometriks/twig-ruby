# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Runtime::Comparison do
  describe '== and != compare numeric strings as numbers' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ page == 1 ? "y" : "n" }}{{ page != 1 ? "y" : "n" }}{{ 1 != "1" ? "y" : "n" }}',
          '{{ "1e3" == "1000" ? "y" : "n" }}{{ " 1" == 1 ? "y" : "n" }}{{ "1 " == "1" ? "y" : "n" }}',
          '{{ "abc" == 0 ? "y" : "n" }}{{ 1.0 == 1 ? "y" : "n" }}{{ "1.0" == "1" ? "y" : "n" }}',
        ]
      end
      let(:outputs) do
        %w[
          ynn
          yyy
          nyy
        ]
      end
      let(:locals) { { page: '1' } }
    end
  end

  describe 'null and booleans compare as PHP does' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ null == 0 ? "y" : "n" }}{{ null == "" ? "y" : "n" }}{{ null == "0" ? "y" : "n" }}',
          '{{ null == [] ? "y" : "n" }}{{ false == "0" ? "y" : "n" }}{{ true == "a" ? "y" : "n" }}',
          '{{ [] == false ? "y" : "n" }}{{ null < -1 ? "y" : "n" }}{{ null <=> 0 }}',
          '{% set x %}0{% endset %}{{ x == false ? "y" : "n" }}{{ x == true ? "y" : "n" }}' \
          '{{ false == x ? "y" : "n" }}{{ x == "0" ? "y" : "n" }}',
        ]
      end
      let(:outputs) do
        %w[
          yyn
          yyy
          yy0
          nyny
        ]
      end
    end
  end

  describe 'ordering compares numeric strings as numbers and other strings byte by byte' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ 2 < "10" ? "y" : "n" }}{{ "10" < "9" ? "y" : "n" }}{{ "abc" < "abd" ? "y" : "n" }}',
          '{{ null < 1 ? "y" : "n" }}{{ 1 > null ? "y" : "n" }}{{ "9" >= 10 ? "y" : "n" }}{{ "9" <= 10 ? "y" : "n" }}',
          '{{ 2 <=> "10" }}{{ "10" <=> "9" }}{{ "a" <=> "b" }}{{ 1 <=> "1a" }}',
        ]
      end
      let(:outputs) do
        [
          'yny',
          'yyny',
          '-11-1-1',
        ]
      end
    end
  end

  describe 'arrays compare by size and then element by element' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ [1, 2] <=> [1, 3] }}{{ [1, 2, 3] <=> [5] }}{{ (1..3) == [1, 2, 3] ? "y" : "n" }}',
          '{{ {a: 1, b: 2} == {b: 2, a: 1} ? "y" : "n" }}{{ {"0": "a"} == ["a"] ? "y" : "n" }}',
          '{{ {a: 1} < {b: 1} ? "y" : "n" }}{{ {a: 1} > {b: 1} ? "y" : "n" }}',
          '{{ [0] > 5 ? "y" : "n" }}{{ "a" > [0] ? "y" : "n" }}',
        ]
      end
      let(:outputs) do
        [
          '-11y',
          'yy',
          'nn',
          'yn',
        ]
      end
    end
  end

  describe 'NAN compares as PHP does' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{% set nan = (-8) ** 0.5 %}{{ nan == nan ? "y" : "n" }}{{ nan < 1 ? "y" : "n" }}{{ nan > 1 ? "y" : "n" }}',
          '{% set nan = (-8) ** 0.5 %}{{ 1 > nan ? "y" : "n" }}{{ "1" > nan ? "y" : "n" }}{{ "1" <=> nan }}',
        ]
      end
      let(:outputs) do
        %w[
          nnn
          nn1
        ]
      end
    end
  end

  describe 'integers too big for PHP compare as strings when they round alike' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ "9223372036854775808" == "9223372036854775809" ? "y" : "n" }}',
          '{{ "1e1000" == "2e1000" ? "y" : "n" }}{{ "1e1000" == "1e1000" ? "y" : "n" }}',
        ]
      end
      let(:outputs) do
        %w[
          n
          ny
        ]
      end
    end
  end

  describe 'max and min compare mixed values' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ max(1, null) }}|{{ max([null, 1]) }}|{{ max([1, "a"]) }}|{{ min([2, "1"]) }}',
          '{{ max(1, "2") }}|{{ min(-1, null) }}|{{ max("10", "9") }}|{{ max({a: "10", b: 9}) }}',
          '{{ max({a: 1}, {b: 1})|keys|join }}{{ max([{a: 1}, {b: 1}])|keys|join }}',
          '{{ min({a: 1}, {b: 1})|keys|join }}{{ min([{a: 1}, {b: 1}])|keys|join }}',
        ]
      end
      let(:outputs) do
        [
          '1|1|a|1',
          '2||10|10',
          'ba',
          'ab',
        ]
      end
    end
  end

  describe 'sort without an arrow compares mixed values' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ [10, 9, "8a", 1]|sort|join(",") }}|{{ ["10", "9", "1e1"]|sort|join(",") }}',
          '{{ [3, null, 1]|sort|join(",") }}|{{ {b: 2, a: "1", c: null}|sort|keys|join }}',
          '{{ ["b", 1, "a", 1.5, "1"]|sort|join(",") }}',
        ]
      end
      let(:outputs) do
        [
          '1,8a,9,10|9,10,1e1',
          ',1,3|cab',
          '1,1,1.5,a,b',
        ]
      end
    end
  end

  describe 'other objects compare with Ruby\'s <=> and ==' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ early < late ? "y" : "n" }}{{ early >= late ? "y" : "n" }}{{ early <=> late }}',
          '{{ early == other_early ? "y" : "n" }}{{ max(early, late) == late ? "y" : "n" }}',
          '{{ object == object ? "y" : "n" }}{{ object == other ? "y" : "n" }}{{ object == null ? "y" : "n" }}',
          '{{ unsaved == other_unsaved ? "y" : "n" }}{{ unsaved != other_unsaved ? "y" : "n" }}' \
          '{{ unsaved in [other_unsaved] ? "y" : "n" }}{{ unsaved <= other_unsaved ? "y" : "n" }}' \
          '{{ unsaved == unsaved ? "y" : "n" }}',
        ]
      end
      let(:outputs) { %w[yn-1 yy ynn nynny] }
      let(:locals) do
        {
          early: Date.new(2024, 1, 1),
          other_early: Date.new(2024, 1, 1),
          late: Date.new(2024, 6, 1),
          object: Object.new,
          other: Object.new,
          unsaved: unsaved_model.new,
          other_unsaved: unsaved_model.new,
        }
      end
      # Like an unsaved ActiveRecord model, whose <=> compares the nil keys
      # of any two as equal while == tells them apart
      let(:unsaved_model) do
        Class.new do
          def <=>(_other)
            0
          end
        end
      end
    end
  end
end
