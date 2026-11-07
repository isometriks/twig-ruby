# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Compiler do
  # Ruby drops a CR before a LF in source, so a string with one can't be
  # written in a %q literal
  context 'with an escaped \r\n in a string literal' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{{ "a\r\nb"|length }}',
          '{{ s|replace({"\r\n": "|"})|json_encode|raw }}',
          '{{ {"a\r\nb": 1}|keys|first|length }}',
          '{{ "a\r\n#{s}"|length }}',
          '{{ "a\rb"|length }}',
        ]
      end

      let(:outputs) do
        ['4', '"a|b"', '4', '7', '3']
      end

      let(:locals) do
        { s: "a\r\nb" }
      end
    end
  end
end
