# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Extension::Core do
  context 'filters' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          Hello {{ name|capitalize }}!
          Hello{{ nil|capitalize }}!
          Hello {{ name|upper }}!
          Hello{{ nil|upper }}!
          {{ "HeLLo WoRlD!"|lower }}
          Hello{{ nil|lower }}!
          {{ "<h1>HEllO WorlD!</h1>"|lower }}
          {{ "hello world!"|title }}
          Hello{{ nil|title }}!
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
          {{ [1, 2, 4, 5]|filter(n => n % 2 == 0)|values }}
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
          {{ "one,two,three,four,five"|split(",", -2)|join("|") }}
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
          {% set func = x => 'Hello '~x %}{{ func|invoke('World!') }}
          {{ [3, 2, 1]|reverse(preserveKeys=true) }}
          {{ asdf ?? 'OK' }}
        INPUTS
      end

      let(:outputs) do
        <<~OUTPUTS
          Hello World!
          Hello!
          Hello WORLD!
          Hello!
          hello world!
          Hello!
          &lt;h1&gt;hello world!&lt;/h1&gt;
          Hello World!
          Hello!
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
          [{"0":1,"1":2},{"2":3,"3":"fill"}]
          Hello World!
          one|two|three,four,five
          one|two|three
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
          Hello World!
          [1, 2, 3]
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
          {{ block("greeting", "blocks.twig") is defined ? "OK" : "KO" }}
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

  describe '#self.compare' do
    it { expect(described_class.compare(:a, 'a')).to eq(0) }
    it { expect(described_class.compare(:a, :b)).to eq(-1) }
    it { expect(described_class.compare(:b, 'a')).to eq(1) }
    it { expect(described_class.compare('b', :a)).to eq(1) }
  end

  it_behaves_like 'render_and_raise' do
    let(:loader) do
      Twig::Loader::Hash.new(
        {
          'template.twig' => '{{ include("include.twig") }}',
          'include.twig' => "\n\n\n{{ include('unknown.twig') }}",
        }
      )
    end
    let(:error) { Twig::Error::Loader }
    let(:message) { /"unknown.twig" is not defined in "include.twig" at line 4/ }
  end

  it_behaves_like 'render_and_raise' do
    let(:loader) do
      Twig::Loader::Hash.new(
        {
          'template.twig' => '{{ include("include.twig") }}',
          'include.twig' => "\n\n\n{{ block('unknown') }}",
        }
      )
    end
    let(:error) { Twig::Error::Runtime }
    let(:message) { /Block "unknown" on template "include.twig" does not exist in "include.twig" at line 4/ }
  end

  describe '#self.length' do
    it 'gets length of strings' do
      expect(described_class.length('Hello World!')).to eq(12)
    end

    it 'gets length of an integer' do
      expect(described_class.length(1234)).to eq(4)
    end

    it 'gets length of an array' do
      expect(described_class.length([1, 2, 3])).to eq(3)
    end

    it 'gets length of a hash' do
      expect(described_class.length({ a: 1, b: 2 })).to eq(2)
    end
  end

  describe '#self.convert_date' do
    let(:extension) { described_class.new }

    it 'returns current date when using "now"' do
      freeze_time do
        expect(extension.convert_date('now')).to eq(Time.now)
      end
    end

    it 'returns a date from an epoch' do
      expect(extension.convert_date(1_610_612_800)).to eq(Time.at(1_610_612_800))
    end

    it 'returns a date from a date string' do
      expect(extension.convert_date('2015-08-08')).to eq(Time.utc(2015, 8, 8))
    end
  end

  describe '#self.max' do
    it 'gets the maximum value from the arguments' do
      expect(described_class.max(1, 2, 3)).to eq(3)
    end

    it 'uses first argument if not passed multiple' do
      expect(described_class.max([1, 2, 3])).to eq(3)
    end

    it 'gets the maximum value of hash values' do
      expect(described_class.max({ a: 1, b: 2 })).to eq(2)
    end
  end

  describe '#self.compare' do
    it 'can compare strings' do
      expect(described_class.compare('a', 'b')).to eq(-1)
      expect(described_class.compare('b', 'a')).to eq(1)
      expect(described_class.compare('a', 'a')).to eq(0)
    end

    it 'can compare symbols' do
      expect(described_class.compare(:a, :b)).to eq(-1)
      expect(described_class.compare(:b, :a)).to eq(1)
      expect(described_class.compare(:a, :a)).to eq(0)
    end

    it 'can compare integers' do
      expect(described_class.compare(1, 2)).to eq(-1)
      expect(described_class.compare(2, 1)).to eq(1)
      expect(described_class.compare(1, 1)).to eq(0)
    end

    it 'can compare strings to symbols' do
      expect(described_class.compare('a', :b)).to eq(-1)
      expect(described_class.compare(:b, 'a')).to eq(1)
      expect(described_class.compare('a', :a)).to eq(0)
    end

    it 'can compare integers and strings' do
      expect(described_class.compare(1, '2')).to eq(-1)
      expect(described_class.compare('2', 1)).to eq(1)
      expect(described_class.compare(1, '1')).to eq(0)
    end
  end

  describe '#self.enumerable_function' do
    RSpec.shared_examples 'enumerable_function' do
      let(:object) { raise NotImplementedError }
      let(:function) { raise NotImplementedError }
      let(:proc) { raise NotImplementedError }
      let(:result) { raise NotImplementedError }

      it 'gives the correct enumerable function output' do
        expect(described_class.public_send(function, object, proc)).to eq(result)
      end
    end

    shared_context 'upcase_map' do
      let(:function) { :map }
      let(:proc) { ->(v) { v.upcase } } # rubocop:disable Style/SymbolProc
    end

    it_behaves_like 'enumerable_function' do
      include_context 'upcase_map'

      let(:object) { %w[a b c] }
      let(:result) { %w[A B C] }
    end

    it_behaves_like 'enumerable_function' do
      include_context 'upcase_map'

      let(:object) { { a: 'a', b: 'b' } }
      let(:result) { { a: 'A', b: 'B' } }
    end

    it_behaves_like 'enumerable_function' do
      include_context 'upcase_map'

      let(:object) do
        Class.new do
          include Enumerable

          def each
            yield :a, 'a'
            yield :b, 'b'
          end
        end.new
      end
      let(:result) { %w[A B] }
    end
  end

  describe '#get_attribute' do
    let(:loader) { Twig::Loader::Hash.new({}) }
    let(:environment) { Twig::Environment.new(loader) }
    let(:strict) { Twig::Environment.new(loader, { strict_variables: true }) }
    # A missing key raises with the source attached, so the double has to answer
    # what Error::Base asks of it.
    let(:source) { instance_double(Twig::Source, path: nil, name: nil) }

    it 'does not use bracket access if doing a method call' do
      klass = Class.new do
        def [](_)
          99
        end

        def foo
          42
        end
      end.new

      expect(
        described_class.get_attribute(
          environment,
          instance_double(Twig::Source),
          klass,
          :foo,
          Twig::Template::METHOD_CALL
        )
      ).to eq(42)
    end

    it 'uses bracket access even when not a hash or array if doing an array call' do
      object = Class.new(SimpleDelegator).new({ pi: 3.14 })

      expect(
        described_class.get_attribute(
          environment,
          instance_double(Twig::Source),
          object,
          :pi,
          Twig::Template::METHOD_CALL
        )
      ).to eq(3.14)
    end

    def attribute_of(object, attribute, env = environment)
      described_class.get_attribute(env, source, object, attribute, Twig::Template::METHOD_CALL)
    end

    def subscript_of(object, attribute, env = environment)
      described_class.get_attribute(env, source, object, attribute, Twig::Template::ARRAY_CALL)
    end

    context 'when the key is missing' do
      it 'names the keys that exist rather than dumping the object' do
        expect { subscript_of({ 'a' => 'x', 'b' => 'y' }, 'c', strict) }.
          to raise_error(Twig::Error::Runtime, %r{Key "c" for sequence/mapping with keys "a, b" does not exist})
      end

      it 'reports the same way for bracket and dot access' do
        object = { 'a' => 'x' }
        bracket = begin
          subscript_of(object, 'c', strict)
        rescue Twig::Error::Runtime => e
          e.message
        end
        dot = begin
          attribute_of(object, 'c', strict)
        rescue Twig::Error::Runtime => e
          e.message
        end

        expect(bracket).to eq(dot)
      end

      it 'does not double the space when the object has no keys' do
        expect { subscript_of(%w[a b], 5, strict) }.
          to raise_error(Twig::Error::Runtime, %r{sequence/mapping does not exist})
      end
    end

    context 'with a key holding a falsy value' do
      it 'returns false for a string key reached by a string name' do
        expect(subscript_of({ 'flag' => false }, 'flag')).to be(false)
        expect(attribute_of({ 'flag' => false }, 'flag')).to be(false)
      end

      it 'returns false for a symbol key reached by a symbol name' do
        expect(subscript_of({ flag: false }, :flag)).to be(false)
      end

      it 'returns false across the string/symbol divide' do
        expect(subscript_of({ flag: false }, 'flag')).to be(false)
        expect(subscript_of({ 'flag' => false }, :flag)).to be(false)
      end

      it 'returns nil for a key that genuinely holds nil' do
        expect(subscript_of({ 'flag' => nil }, 'flag')).to be_nil
      end

      it 'prefers the key that matches over the other form of the name' do
        # Both keys exist; the one the template asked for wins, even though it
        # holds nil and the other holds something truthy.
        expect(subscript_of({ 'a' => nil, a: 1 }, 'a')).to be_nil
        expect(subscript_of({ 'a' => 1, a: nil }, :a)).to be_nil
      end

      it 'reports a falsy value as defined' do
        expect(
          described_class.get_attribute(
            environment,
            instance_double(Twig::Source),
            { 'flag' => false },
            'flag',
            Twig::Template::ARRAY_CALL,
            defined_test: true
          )
        ).to be(true)
      end
    end

    context 'with an array index' do
      it 'reads from the end with a negative index' do
        expect(subscript_of(%w[a b c], -1)).to eq('c')
        expect(subscript_of(%w[a b c], -3)).to eq('a')
      end

      it 'treats an out-of-range negative index as missing, not as a TypeError' do
        expect { subscript_of(%w[a b c], -99, strict) }.
          to raise_error(Twig::Error::Runtime, /-99/)
      end

      it 'treats an out-of-range positive index as missing' do
        expect { subscript_of(%w[a b c], 99, strict) }.
          to raise_error(Twig::Error::Runtime, /99/)
      end

      it 'returns nil for an out-of-range index when not strict' do
        expect(subscript_of(%w[a b c], -99)).to be_nil
        expect(subscript_of(%w[a b c], 99)).to be_nil
      end
    end

    context 'with a collection' do
      it 'calls methods on an array rather than subscripting with the name' do
        expect(attribute_of(%w[a b], :any?)).to be(true)
        expect(attribute_of(%w[a b], :size)).to eq(2)
        expect(attribute_of([], :any?)).to be(false)
      end

      it 'calls methods on a hash rather than returning nil' do
        expect(attribute_of({ 'a' => 1 }, :any?)).to be(true)
        expect(attribute_of({}, :any?)).to be(false)
      end

      it 'still prefers a real key over a method of the same name' do
        expect(attribute_of({ 'size' => 'from key' }, 'size')).to eq('from key')
        expect(attribute_of({ 'first' => 'Ada' }, 'first')).to eq('Ada')
      end

      it 'still prefers a real index over a method name' do
        expect(attribute_of(%w[a b], 0)).to eq('a')
      end
    end

    context 'with a method the object only claims to respond to' do
      let(:liar) do
        Class.new do
          def respond_to_missing?(name, include_all = false)
            name.to_sym == :hidden || super
          end

          private

          def hidden
            'private'
          end
        end.new
      end

      it 'does not reach private methods' do
        expect { attribute_of(liar, :hidden) }.to raise_error(NoMethodError)
      end
    end
  end
end
