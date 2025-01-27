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
        OUTPUTS
      end

      let(:locals) { { name: 'world', line: "Hello\nWorld!" } }
    end
  end
end
