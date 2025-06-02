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
          {{ "<h1>HEllO WorlD!</h1>"|lower }}
          {{ "hello world!"|title }}
          {{ "<h1>Raw Hello World!</h1>"|raw }}
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
          {% block hello "Hello" %}{{ block("hello") }}
          {{ hash.(:key) }}
          {{ hash.(key) }}
          {{ madeup|default("Hello World!") }}
          {{ madeup[name]|default("Hello World!") }}
          {{ madeup['key']|default("Hello World!") }}
          {{ madeup.foo|default("Hello World!") }}
          {{ class.attribute(...args) }}
          {{ class.attribute("Hello", ...args2) }}
          {{ class.attribute(sep: "-", ...args) }}
          {{ class.attribute(...{ sep: "*" }, ...args) }}
          {{ class.attribute_hash(arg1: "Hello", arg2: "World!") }}
          {{ class.attribute_hash(...args_hash) }}
          {{ [...[1, 2, 3], ...[4, 5]]|join(", ") }}
          {{ { ...{ a: "Hello" }, ...{ b: "World!" } }|values|join(" ") }}
          {{ § }}
          {{ [1, 2, 3]|batch(2, :fill)|json_encode|raw }}
          {{ "Hello,World!"|split(",")|join(" ") }}
          {{ "one,two,three,four,five"|split(",", 3)|join("|") }}
          {{ ([1,2,3] has some n => n % 2 == 0) ? "OK" : "KO" }}
          {{ ([1,1,1] has some n => n % 2 == 0) ? "KO" : "OK" }}
          {{ ([1,2,3] has every n => n % 2 == 0) ? "KO" : "OK" }}
          {{ ([2,4,6] has every n => n % 2 == 0) ? "OK" : "KO" }}
          {{ html|striptags|trim }}
          {{ html|striptags(['h1'])|trim|raw }}
          {{ ["a", "b"]|join(and_glue=" or ") }}
          {{ ["a", "b"]|join(...{glue: " - "}) }}
          {% for matches in [1,2,3] %}{{ matches }}{% endfor %}
          {{ numbers[1:3]|join }}
          {{ numbers[slice_start:3]|join }}
          {{ numbers[slice_start:slice_end]|join }}
          {% for i in range(0, 10) if i > 5 %}{{ i }},{% endfor %}
        INPUTS
      end

      let(:outputs) do
        <<~OUTPUTS
          Hello World!
          Hello WORLD!
          hello world!
          &lt;h1&gt;hello world!&lt;/h1&gt;
          Hello World!
          <h1>Raw Hello World!</h1>
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
          HelloHello
          value
          value
          Hello World!
          Hello World!
          Hello World!
          Hello World!
          Hello World!
          Hello Hello
          Hello-World!
          Hello*World!
          Hello World!
          Hello World!
          1, 2, 3, 4, 5
          Hello World!
          Special character
          [{"0":1,"1":2},{"2":3,"1":"fill"}]
          Hello World!
          one|two|three,four,five
          OK
          OK
          OK
          OK
          Hello World! How are you?
          <h1>Hello World!</h1>How are you?
          a or b
          a - b
          123
          234
          234
          234
          6,7,8,9,10,
        OUTPUTS
      end

      let(:locals) do
        {
          name: 'world',
          line: "Hello\nWorld!",
          millennium: DateTime.new(2021, 1, 1, 0, 0, 0),
          array_of_hashes: [{ fruit: 'Apple' }, { fruit: 'Orange' }],
          empty: nil,
          key: :key,
          numbers: [1, 2, 3, 4, 5],
          slice_start: 1,
          slice_end: 3,
          hash: { key: 'value' },
          args: %w[Hello World!],
          args2: ['Hello'],
          args_hash: { arg1: 'Hello', arg2: 'World!' },
          class: Class.new do
            def attribute(arg1, arg2, sep: ' ')
              [arg1, arg2].join(sep)
            end

            def attribute_hash(arg1: nil, arg2: nil)
              [arg1, arg2].join(' ')
            end
          end.new,
          §: 'Special character',
          html: '<h1>Hello World!</h1><small>How are you?</small>',
        }
      end
    end
  end

  context 'functions' do
    before do
      stub_const('A', Class.new)
      stub_const('A::CONST', 'Hello World!')
      stub_const('A::INT', 5)
      stub_const('A::B::CONST', 'Goodbye World!')
    end

    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          Hello {{ include("include.twig") }}
          {{ [1, 2]|sort((a, b) => (b - a)) }}
          {{ [3, 2, 1]|sort }}
          {{ { a: 2, b: 1 }|sort((a, b) => (a[1] - b[1])) }}
          {{ { b: 2, a: 1 }|sort }}
          {{ [1, 2, 3]|join }}
          {{ [1, 2, 3]|join(", ") }}
          {{ [1, 2, 3]|join(", ", ", and ") }}
          {{ [1, 2, 3]|keys }}
          {{ {a: 1, b: 2, c: 3 }|keys|join(", ") }}
          {{ {a, b: 2, c: 3 }|values|join(", ") }}
          {{ [1, 2, 3]|values|join(", ") }}
          {% for i in range(0, 5) %}{{ cycle(cycles, i) }}-{% endfor %}
          {{ source('source.twig') }}
          {{ block("greeting", "blocks.twig") }} {{ block("message", "blocks.twig")}}
          {{ constant("A::CONST") }}
          {{ constant("CONST", instance) }}
          {{ constant("A::B::CONST") }}
          {{ constant("A::CONST") is defined ? "OK" : "KO" }}
          {{ constant("A::B::CONST") is defined ? "OK" : "KO" }}
          {{ constant("A::ASDF") is defined ? "KO" : "OK" }}
          {{ 5 is constant("A::INT") ? "OK" : "KO" }}
          {{ 5 is constant("INT", instance) ? "OK" : "KO" }}
          {{ not false?'OK':'KO' }}
          {{ nil?? 'OK' }}
        INPUTS
      end

      let(:outputs) do
        <<~OUTPUTS
          Hello World!
          [2, 1]
          [1, 2, 3]
          {b: 1, a: 2}
          {a: 1, b: 2}
          123
          1, 2, 3
          1, 2, and 3
          [0, 1, 2]
          a, b, c
          1, 2, 3
          1, 2, 3
          tic-tac-toe-tic-tac-toe-
          {{ Hello World! }}
          Hello World!
          Hello World!
          Hello World!
          Goodbye World!
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
          a: 1,
          cycles: %w[tic tac toe],
          instance: A.new,
        }
      end

      let(:templates) do
        {
          'include.twig' => 'World!',
          'source.twig' => '{{ Hello World! }}',
          'blocks.twig' => '{% block greeting "Hello" %}{% block message "World!" %}',
        }
      end
    end
  end
end
