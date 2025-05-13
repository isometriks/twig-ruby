# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Call do
  it_behaves_like 'render_and_assert' do
    let(:extensions) do
      [
        Class.new(Twig::Extension::Base) do
          def filters
            [
              Twig::TwigFilter.new('foo', lambda(&:reverse)),
            ]
          end
        end.new,
      ]
    end

    let(:inputs) do
      [
        '{{ "!dlroW olleH"|foo }}',
      ]
    end

    let(:outputs) do
      [
        'Hello World!',
      ]
    end
  end
end
