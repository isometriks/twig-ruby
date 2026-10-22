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
      let(:outputs) { %w[arg default GLOBAL a,g,varargs] }
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
