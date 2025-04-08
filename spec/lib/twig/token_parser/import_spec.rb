# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Import do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% import "macro.twig" as macros %}{{ macros.greeting("Hello") }}
        {% import "macro.twig" as macros %}{{ macros.greeting("Hello", "World!") }}
        {% import "macro.twig" as macros %}{{ macros.greeting("Hello", message = "Universe!") }}
        {% import "macro.twig" as macros %}{{ macros.greeting("Hello", message: "Ruby!") }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello Earth!
        Hello World!
        Hello Universe!
        Hello Ruby!
      OUTPUTS
    end

    let(:locals) { { template: 'include' } }

    let(:templates) do
      {
        'macro.twig' => '{% macro greeting(greeting, message = "Earth!") %}{{ greeting }} {{ message }}{% endmacro %}',
      }
    end
  end
end
