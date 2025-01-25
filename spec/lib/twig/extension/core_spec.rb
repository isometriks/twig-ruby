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
          4 sleeping {{ "dog"|pluralize(4) }} lie
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
        OUTPUTS
      end

      let(:locals) { { name: 'world', line: "Hello\nWorld!" } }
    end
  end
end
