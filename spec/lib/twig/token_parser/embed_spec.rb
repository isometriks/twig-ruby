# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Macro do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      [
        '{% embed "embed.twig" %}{% endembed %}',
        '{% embed "embed.twig" %}{% block greeting "Goodbye" %}{% block message "Universe!" %}{% endembed %}',
      ]
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Goodbye Universe!
      OUTPUTS
    end

    let(:templates) do
      {
        'embed.twig' => '{% block greeting "Hello" %} {% block message "World!" %}',
      }
    end
  end
end
