# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Macro do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      [
        # Using equal for args (=)
        '{% macro greeting(greeting, message = "Earth") %}{{ greeting }} {{ message }}{% endmacro %}
         {{- _self.greeting(greeting: "Hello", message: "World!") }}',

        '{% macro greeting(greeting, message = "Earth") %}{{ greeting }} {{ message }}{% endmacro %}
         {{- _self.greeting(message: "World!", greeting: "Hello") }}',

        '{% macro greeting(greeting, message = "Earth") %}{{ greeting }} {{ message }}{% endmacro %}
         {{- _self.greeting("Hello", message: "World!") }}',

        '{% macro greeting(greeting, message = "Earth") %}{{ greeting }} {{ message }}{% endmacro %}
         {{- _self.greeting("Hello", "World!") }}',

        # Using colon for args (:)
        '{% macro greeting(greeting, message: "Earth") %}{{ greeting }} {{ message }}{% endmacro %}
         {{- _self.greeting(greeting: "Hello", message: "World!") }}',

        '{% macro greeting(greeting, message: "Earth") %}{{ greeting }} {{ message }}{% endmacro %}
         {{- _self.greeting(message: "World!", greeting: "Hello") }}',

        '{% macro greeting(greeting, message: "Earth") %}{{ greeting }} {{ message }}{% endmacro %}
         {{- _self.greeting("Hello", message: "World!") }}',

        '{% macro greeting(greeting, message: "Earth") %}{{ greeting }} {{ message }}{% endmacro %}
         {{- _self.greeting("Hello", "World!") }}',

        '{% from "macro.twig" import greeting %}{{ greeting("Hello", "World!") }}',
        '{% from "macro.twig" import greeting as greet %}{{ greet("Hello", "World!") }}',

        '{% macro §(message) %}{{ message }}{% endmacro %}
         {{- _self.§("Hello World!") }}',

        '{% macro negative_number(nb = -1) %}{{ nb }}{% endmacro %}{{ _self.negative_number() }}',
        '{% macro negative_number2(nb = --1) %}{{ nb }}{% endmacro %}{{ _self.negative_number2() }}',
        '{% macro m() %}{% endmacro %}{{ _self.m is defined ? "OK" : "KO" }}',
        '{{ _self.m is defined ? "KO" : "OK" }}',
        '{% from "macro.twig" import greeting %}{{ greeting is defined ? "OK" : "KO" }}',
        '{% extends "macro.twig" %}{% block content %}{{ _self.greeting is defined ? "OK" : "KO" }}{% endblock %}',
      ]
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        Hello World!
        -1
        1
        OK
        OK
        OK
        OK
      OUTPUTS
    end

    let(:templates) do
      {
        'macro.twig' => '{% block content "" %}{% macro greeting(greeting, message = "Earth") %}{{ greeting }} ' \
                        '{{ message }}{% endmacro %}',
      }
    end
  end

  it 'rejects a colon default for the variadic argument, like an equals default' do
    loader = Twig::Loader::Hash.new({ 'index.twig' => '{% macro f(...rest: 1) %}{% endmacro %}' })

    expect { Twig::Environment.new(loader).load('index.twig') }.
      to raise_error(
        Twig::Error::Syntax,
        'The variadic argument "rest" in macro "f" cannot have a default value in "index.twig" at line 1.'
      )
  end

  # Ruby extension: like a Rails helper, a macro called without arguments needs no
  # parentheses. Twig PHP 4 raises a SyntaxError for these.
  context 'when a macro is called without parentheses' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{% import "forms.twig" as forms %}{{ forms.button }}',
          '{% macro hello() %}Hello{% endmacro %}{{ _self.hello }}',
          '{% import _self as macros %}{% macro hello() %}Hello{% endmacro %}{% set name = "hello" %}' \
          '{{ macros.(name) }}',
          '{% macro hello(name = "World") %}Hello {{ name }}{% endmacro %}{{ _self.hello }}',
          '{% import "forms.twig" as forms %}{{ forms.button is defined ? "OK" : "KO" }}',
        ]
      end
      let(:outputs) { ['<button>OK</button>', 'Hello', 'Hello', 'Hello World', 'OK'] }
      let(:templates) do
        { 'forms.twig' => '{% macro button(label = "OK") %}<button>{{ label }}</button>{% endmacro %}' }
      end
    end

    it 'still requires the arguments that have no default value' do
      loader = Twig::Loader::Hash.new({ 'index.twig' => '{% macro m(a) %}{% endmacro %}{{ _self.m }}' })

      expect { Twig::Environment.new(loader).load('index.twig').render }.
        to raise_error(Twig::Error::Runtime, /Value for argument "a" is required for macro "m"/)
    end
  end

  context 'when a macro argument has the same name as a global' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          "{% macro foo(g) %}{{ g }}{% endmacro %}{{ _self.foo('arg') }}",
          "{% macro foo(g = 'default') %}{{ g }}{% endmacro %}{{ _self.foo() }}",
          '{% macro foo() %}{{ g }}{% endmacro %}{{ _self.foo() }}',
          "{% macro foo(a, g) %}{{ _context|keys|join(',') }}{% endmacro %}{{ _self.foo(1, 2) }}",
        ]
      end
      let(:outputs) { %w[arg default GLOBAL a,g] }
      let(:extensions) do
        [
          Class.new(Twig::Extension::Base) do
            def globals
              { 'g' => 'GLOBAL' }
            end
          end.new,
        ]
      end
    end
  end
end
