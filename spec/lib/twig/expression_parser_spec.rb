# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

module Twig
  RSpec.describe ExpressionParser do
    context 'operators of difference precedence' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ 1 + 2 * 3 }}
            {{ 2 * 3 + 1 }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            7
            7
          OUTPUTS
        end
      end
    end

    context 'recognizes null as a keyword' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ null }}
            {{ NULL }}
            {{ nil }}
          INPUTS
        end

        let(:outputs) do
          [
            '',
            '',
            '',
          ]
        end
      end
    end

    context 'parses sequence expressions' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ names[0] }}
            {{ math[0] + math[1] }}
            {{ math[0] == math[1] ? "OK" : "KO" }}
            {{ ["Hello", "World!"][0] }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            Craig
            3
            KO
            Hello
          OUTPUTS
        end

        let(:locals) { { math: [1, 2], names: %w[Craig Bob] } }
      end
    end

    context 'parses mapping expressions' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ { hello: "Hello", world: "World!" }["hello"] }}
            {{ names["first"] }} {{ names["last"] }}
            {{ names[:first] }} {{ names[:last] }}
            {{ { hello: :world }[:hello] }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            Hello
            Hello World!
            Hello World!
            world
          OUTPUTS
        end

        let(:locals) { { names: { first: 'Hello', last: 'World!' } } }
      end
    end

    context 'with class variable in call context' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ @greeting }}
            {{ @greeting_array[0] }} {{ @greeting_array[1] }}
            {{ @greeting_array.join(" ") }}
            {% extends "parent.twig" %}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            Hello World!
            Hello World!
            Hello World!
            Hello World!
          OUTPUTS
        end

        let(:call_context) do
          Class.new do
            def initialize
              @greeting = 'Hello World!'
              @greeting_array = %w[Hello World!]
            end
          end.new
        end

        let(:templates) do
          {
            'parent.twig': '{% block content %}{{ @greeting }}{% endblock %}',
          }
        end
      end
    end

    context 'with an instance variable as an attribute name' do
      it_behaves_like 'render_and_raise' do
        let(:template) { '{{ foo.@bar }}' }
        let(:error) { Twig::Error::Syntax }
        let(:message) { /Expected name or number, got value "@bar" of type "instance variable"/ }
      end
    end

    context 'with arrow function' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ [1, 2]|map(n => n * 2) }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            [2, 4]
          OUTPUTS
        end
      end
    end

    context 'with multiline strings' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{{ "Hello " ~
                 # Stopping by for a comment
               "World!" }}',
          ]
        end

        let(:outputs) do
          ['Hello World!']
        end
      end
    end

    context 'parses comment blocks' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            Hello{# nothing here #} World!
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            Hello World!
          OUTPUTS
        end

        let(:locals) do
          {
            foo: { not: 'not' },
          }
        end
      end
    end

    context 'with names ending in ?' do
      it_behaves_like 'render_and_assert' do
        let(:options) { { allow_helper_methods: true } }

        let(:inputs) do
          [
            '{% if user_signed_in? %}Y{% else %}N{% endif %}',
            '{% if not user_signed_in? %}Y{% else %}N{% endif %}',
            '{% if admin? %}Y{% else %}N{% endif %}',
            '{% if user_signed_in? and admin? %}Y{% else %}N{% endif %}',
            '{% if user_signed_in? or admin? %}Y{% else %}N{% endif %}',
            "{% if current_page?('/home') %}Y{% else %}N{% endif %}",
            "{% if current_page?('/away') %}Y{% else %}N{% endif %}",
            "{{ content_for?('sidebar') }}",
            '{{ user_signed_in? }}',
            "{{ user_signed_in? ? 'in' : 'out' }}",
            "{{ admin? ? 'admin' : 'user' }}",
            "{{ user_signed_in? ? admin? : 'n/a' }}",
            "{{ admin? ?: 'none' }}",
            "{{ [user_signed_in?, admin?]|join(',') }}",
            '{{ user_signed_in?|default(false) }}',
            '{{ user.errors.any? }}',
            "{{ user.errors.any? ? 'y' : 'n' }}",
            '{{ user.registerable? }}',
          ]
        end

        let(:outputs) do
          [
            'Y',
            'N',
            'N',
            'N',
            'Y',
            'Y',
            'N',
            'true',
            'true',
            'in',
            'user',
            'false',
            'none',
            'true,false',
            'true',
            'true',
            'y',
            'false',
          ]
        end

        let(:locals) do
          { user: Struct.new(:errors, :registerable?).new(['oops'], false) }
        end

        let(:call_context) do
          Class.new do
            def user_signed_in? = true
            def admin? = false
            def current_page?(path) = path == '/home'
            def content_for?(name) = name == 'sidebar'
          end.new
        end
      end
    end

    context 'with a ? straight after a name that starts a ternary' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{{ x?1:2 }}',
            '{{ y?1:2 }}',
            '{{ x? a : b }}',
            "{{ x?'a':'b' }}",
            '{{ x?-1:1 }}',
            '{{ x?[1]|first:2 }}',
            '{{ y?:"elvis" }}',
            '{{ x?:"elvis" }}',
            '{{ nope??"coalesce" }}',
            '{{ x ? a : b }}',
            '{{ y ?: b }}',
            '{{ nope ?? b }}',
          ]
        end

        let(:outputs) do
          [
            '1',
            '2',
            'A',
            'a',
            '-1',
            '1',
            'elvis',
            'true',
            'coalesce',
            'A',
            'B',
            'B',
          ]
        end

        let(:locals) do
          { x: true, y: false, a: 'A', b: 'B' }
        end
      end
    end

    context 'with a mapping key ending in ?' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{{ {visible?: true}|keys|join }}',
            '{{ {a: 1, x?:2}|keys|join(",") }}',
            '{{ {visible? : true}|keys|join }}',
            '{{ {k?: x? :y : 2}|first }}',
          ]
        end

        let(:outputs) do
          %w[visible? a,x? visible? y]
        end

        let(:locals) do
          { x: true }
        end
      end
    end

    context 'with a ? and then a symbol' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{{ x? :y : 2 }}',
            '{{ y? :a : :b }}',
            '{% if x? :y : z %}T{% else %}F{% endif %}',
            '{{ x ? :y : 2 }}',
            '{{ y ? :a : :b }}',
            '{{ h.b ? :yes : :no }}',
            '{{ y ? :a }}',
            '{{ y ? :x ? c : d }}',
            '{{ y ? :x and z ? c : d }}',
            '{{ y ? :a : x ? :c : :d }}',
          ]
        end

        let(:outputs) do
          %w[y b T y b yes A C D c]
        end

        let(:locals) do
          { x: true, y: false, z: false, a: 'A', c: 'C', d: 'D', h: { 'b' => true } }
        end
      end
    end

    # A ternary open before a spaced ? : keeps its :, so the ? : is the ?:
    # alias, as in Twig PHP: c ? (a ?: x) : 'z'
    context 'with a spaced ? : inside a ternary' do
      sources = [
        "{{ c ? a ? :x : 'z' }}",
        '{{ c ? d ? a ? :x : y : z }}',
        '{{ c ? a ? :x ? d : y : z }}',
        '{% for i in [1] %}{{ c ? a ? :x : loop.index }}{% endfor %}',
        "{{ \"\#{c ? a ? :x : z}\" }}",
      ]

      context 'when the condition is false' do
        it_behaves_like 'render_and_assert' do
          let(:inputs) { sources }
          let(:outputs) { %w[z Z Z 1 Z] }
          let(:locals) { { a: 1, c: false, d: 1, x: 'X', y: 'Y', z: 'Z' } }
        end
      end

      context 'when the condition is true' do
        it_behaves_like 'render_and_assert' do
          let(:inputs) { sources }
          let(:outputs) { %w[X X 1 X X] }
          let(:locals) { { a: 0, c: true, d: 1, x: 'X', y: 'Y', z: 'Z' } }
        end
      end
    end

    it 'lexes a long chain of spaced ? : quickly' do
      environment = Twig::Environment.new(Twig::Loader::Hash.new({}))
      sources = [' ? :b%d', ' ? :b%d : c%d', ' ? :b%d ? c%d : d'].map do |link|
        "{{ a#{(1..200).map { |i| format(link, i, i) }.join} }}"
      end

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      sources.each { |source| environment.tokenize(Twig::Source.new(source, 'index')) }

      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 2
    end

    context 'with an attribute ending in ? before an operator that goes on with it' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{{ user.pred? - 1 }}',
            '{{ user.pred?+ 1 }}',
            '{{ user.pred? (5) }}',
            '{{ user.list?[0] }}',
            "{{ user.pred? 'y' : 'n' }}",
          ]
        end

        let(:outputs) do
          %w[0 2 5 a y]
        end

        let(:locals) do
          {
            user: Class.new do
              def pred?(value = 1) = value
              def pred = true
              def list? = %w[a b]
            end.new,
          }
        end
      end
    end

    context 'with an arrow function argument ending in ?' do
      it_behaves_like 'render_and_raise' do
        let(:template) { '{{ [1]|map(x? => x?)|join }}' }
        let(:error) { Twig::Error::Syntax }
        let(:message) { /An arrow function argument cannot end with "\?" \("x\?"\)/ }
      end
    end

    context 'with an arrow function argument list ending in ?' do
      it_behaves_like 'render_and_raise' do
        let(:template) { '{{ [1]|map((x?, k) => x?)|join }}' }
        let(:error) { Twig::Error::Syntax }
        let(:message) { /An arrow function argument cannot end with "\?" \("x\?"\)/ }
      end
    end

    context 'with an arrow function argument that is not a variable' do
      it_behaves_like 'render_and_raise' do
        let(:template) { '{{ [1]|map(true => true)|join }}' }
        let(:error) { Twig::Error::Syntax }
        let(:message) { /The arrow function argument must be a list of variables or a single variable/ }
      end
    end

    context 'with a macro argument ending in ?' do
      it_behaves_like 'render_and_raise' do
        let(:template) { '{% macro m(a?) %}{{ a? }}{% endmacro %}{{ _self.m(1) }}' }
        let(:error) { Twig::Error::Syntax }
        let(:message) { /A macro argument cannot end with "\?" \("a\?"\)/ }
      end
    end

    context 'when template has invalid mapping' do
      it_behaves_like 'render_and_raise' do
        let(:template) { '{{ var.call(4,5,,) }}' }
        let(:error) { Twig::Error::Syntax }
        let(:message) { /Unexpected token "punctuation" of value ","/ }
      end
    end

    context 'when an expression is missing' do
      it_behaves_like 'render_and_raise' do
        let(:template) { '{{ 1 + }}' }
        let(:error) { Twig::Error::Syntax }
        let(:message) do
          'Unexpected token "end of print statement" of value "" in "template.twig" at line 1.'
        end
      end
    end

    context 'when arguments are not separated by a comma' do
      it_behaves_like 'render_and_raise' do
        let(:template) { '{{ range(1 2) }}' }
        let(:error) { Twig::Error::Syntax }
        let(:message) do
          'Arguments must be separated by a comma. Unexpected token "number" of value "2" ' \
            '("punctuation" expected with value ",") in "template.twig" at line 1 column 12.'
        end
      end
    end

    context 'with the spread operator' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{% set a = [1, 2] %}{{ [...a, 3]|join(",") }}',
            '{% set m = { a: 1 } %}{{ { ...m, b: 2 }|keys|join(",") }}',
            '{{ max(...[1, 5, 3]) }}',
            '{% macro m(a, b) %}{{ a }}{{ b }}{% endmacro %}{% set args = [1, 2] %}{{ _self.m(...args) }}',
            '{{ [...[1]] ? "yes" : "no" }}',
          ]
        end
        let(:outputs) { ['1,2,3', 'a,b', '5', '12', 'yes'] }
      end
    end

    # Ported from Twig PHP's ExpressionParserTest::getMisplacedSpreadTests
    [
      '{{ ...foo }}',
      '{{ (...foo) }}',
      '{{ -...foo }}',
      '{{ 1 + ...foo }}',
      '{% set bar = ...foo %}',
      '{% do ...foo %}',
      '{% with ...foo %}{% endwith %}',
      '{{ (bar => ...foo)(1) }}',
      '{{ [(...foo)] }}',
      '{{ [1, -...foo] }}',
      '{{ {a: ...foo} }}',
      '{{ {(...foo): 1} }}',
      '{{ bar(-...foo) }}',
      '{{ bar(a: ...foo) }}',
      '{{ bar(a = ...foo) }}',
    ].each do |source|
      context "with a misplaced spread operator in #{source}" do
        it_behaves_like 'render_and_raise' do
          let(:template) { source }
          let(:error) { Twig::Error::Syntax }
          let(:message) do
            'The spread operator can only be used on sequence elements, mapping elements, and call arguments ' \
              'in "template.twig" at line 1.'
          end
        end
      end
    end

    # Ported from Twig PHP's ExpressionParserTest (e5eb95d0d)
    context 'with the literal parser' do
      let(:parsers) { Twig::Environment.new(Twig::Loader::Hash.new({})).expression_parsers }

      it 'has no operator tokens' do
        literal = parsers.by_class(ExpressionParser::Prefix::Literal.name)

        expect(literal.operator_tokens).to eq([])
        expect(literal.name).to eq('literal')
      end

      it 'is not registered as an operator' do
        expect(parsers.by_name(:prefix, 'literal')).to be_nil
        expect(parsers.by_name(:infix, 'literal')).to be_nil
      end

      it 'is still iterated' do
        expect(parsers.to_enum(:each).to_a).to include(an_instance_of(ExpressionParser::Prefix::Literal))
      end

      it 'leaves every other parser with its name and aliases as operator tokens' do
        others = parsers.to_enum(:each).reject { |parser| parser.is_a?(ExpressionParser::Prefix::Literal) }

        expect(others).not_to be_empty
        others.each do |parser|
          expect(parser.operator_tokens).to eq([parser.name, *parser.aliases]), parser.class.name
        end
      end
    end

    context 'with a name called literal' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{% block literal %}x{% endblock %}',
            '{% macro m(literal) %}{{ literal }}{% endmacro %}{{ _self.m(2) }}',
            '{% import _self as literal %}ok',
            '{% macro m() %}M{% endmacro %}{% import _self as literal %}{{ literal.m() }}',
            '{% set literal = 3 %}{{ literal }}',
          ]
        end
        let(:outputs) { %w[x 2 ok M 3] }
      end
    end

    context 'when a parenthesis is not closed' do
      it_behaves_like 'render_and_raise' do
        let(:template) { '{{ (1 2) }}' }
        let(:error) { Twig::Error::Syntax }
        let(:message) do
          'An opened parenthesis is not properly closed. Unexpected token "number" of value "2" ' \
            '("punctuation" expected with value ")") in "template.twig" at line 1 column 7.'
        end
      end
    end
  end
end
