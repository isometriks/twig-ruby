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
      OUTPUTS
    end
  end
end
