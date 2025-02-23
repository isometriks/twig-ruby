# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Extension::Core do
  context 'filters' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          Hello {{ name|capitalize }}!
          Hello {{ name|upper }}!
          {{ "HeLLo WoRlD!"|lower }}
          {{ "hello world!"|title }}
          {{ "<h1>Hello World!</h1>"|raw }}
          {{ ["Hello", "World"]|first }}
          {{ ["Hello", "World"]|last }}
          4 sleeping {{ "dog"|plural(0) }} lie
          {{ "%s %s"|format("Hello", "World!") }}
          {{ "Hello %name%"|replace({'%name%': 'World!'}) }}
          {{ 1234.567|number_format(2) }}
          {{ (-1234)|abs }}
          {{ 1234.567|round(2, :floor) }}
          {{ millennium|date }}
          {{ millennium|date('%Y-%m-%d') }}
          {{ min(1, 2, 3) }}
          {{ max(1, 2, 3) }}
          {% for letter in range('a', 'g', 2) %}{{ letter }}{% endfor %}
          {{ 'Wôrķšpáçè ~~sèťtïñğš~~'|slug('/') }}
          {{ { hello: "world" }|json_encode|raw }}
          {{ array_of_hashes|column(:fruit)|raw }}
          {{ [:hello]|merge([:world]) }}
          {{ { greeting: "Hello" }|merge({ subject: "World!" })|raw }}
          {{ [1, 2, 4, 5]|filter(n => n % 2 == 0) }}
          {{ [1, 2, 4, 5]|find(n => n == 4) }}
          {{ [1, 2, 3]|reduce((acc, n) => acc + n, 0) }}
          {{ [1, 2, 3]|reduce((acc, v, k) => acc + k * v, 0) }}
          {{ 5 is even ? "KO" : "OK" }}
          {{ 4 is even ? "OK" : "KO" }}
          {{ 5 is not even ? "OK" : "KO" }}
          {{ 5 is odd ? "OK" : "KO" }}
          {{ 4 is odd ? "KO" : "OK" }}
          {{ 5 is not odd ? "KO" : "OK" }}
          {{ empty is null ? "OK" : "KO" }}
          {{ empty is nil ? "OK" : "KO" }}
          {{ empty is none ? "OK" : "KO" }}
          {{ 6 is divisible by(3) ? "OK" : "KO" }}
          {{ 6 is divisible by(5) ? "KO" : "OK" }}
          {{ name is same as("world") ? "OK" : "KO" }}
          {{ name is not same as("hello") ? "OK" : "KO" }}
          {{ [1, 2] is sequence ? 'OK' : 'KO' }}
          {{ {a: 1, b: 2} is sequence ? 'KO' : 'OK' }}
          {{ {a: 1, b: 2} is mapping ? 'OK' : 'KO' }}
          {{ [1, 2] is mapping ? 'KO' : 'OK' }}
          {{ [1, 2] is iterable ? 'OK' : 'KO' }}
          {{ {a: 1, b: 2} is iterable ? 'OK' : 'KO' }}
          {{ "Hello World!" is iterable ? 'KO' : 'OK' }}
          {{ [] is empty ? 'OK' : 'KO' }}
          {{ [1, 2, 3] is not empty ? 'OK' : 'KO' }}
        INPUTS
      end

      let(:outputs) do
        <<~OUTPUTS
          Hello World!
          Hello WORLD!
          hello world!
          Hello World!
          <h1>Hello World!</h1>
          Hello
          World
          4 sleeping dogs lie
          Hello World!
          Hello World!
          1,234.57
          1234
          1234.56
          January 1, 2021 00:00
          2021-01-01
          1
          3
          aceg
          workspace/settings
          {"hello":"world"}
          ["Apple", "Orange"]
          [:hello, :world]
          {greeting: "Hello", subject: "World!"}
          [2, 4]
          4
          6
          8
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
          OK
        OUTPUTS
      end

      let(:locals) do
        {
          name: 'world',
          line: "Hello\nWorld!",
          millennium: DateTime.new(2021, 1, 1, 0, 0, 0),
          array_of_hashes: [{ fruit: 'Apple' }, { fruit: 'Orange' }],
          empty: nil,
        }
      end
    end
  end
end
