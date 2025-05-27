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
      OUTPUTS
    end

    let(:templates) do
      {
        'macro.twig' => '{% macro greeting(greeting, message = "Earth") %}{{ greeting }} {{ message }}{% endmacro %}',
      }
    end
  end
end
