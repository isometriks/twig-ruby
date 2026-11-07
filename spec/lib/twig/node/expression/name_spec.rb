# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Name do
  # Any character from U+007F is a name character, as in Twig, but U+007F
  # can't go in a bare Ruby symbol
  context 'with U+007F in a name' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          "{{ a\x7fb }}",
          "{{ a\x7fb is defined ? 1 : 2 }}",
          "{{ a\x7fb ?? 2 }}",
          "{% set c\x7fd = 3 %}{{ c\x7fd }}",
          "{% set c\x7fd %}x{% endset %}{{ c\x7fd }}",
          "{% for k\x7f, v\x7f in {a: 1} %}{{ k\x7f }}{{ v\x7f }}{% endfor %}",
          "{% with {c\x7fd: 5} %}{{ c\x7fd }}{% endwith %}",
        ]
      end

      let(:outputs) do
        %w[1 1 1 3 x a1 5]
      end

      let(:locals) do
        { "a\x7fb" => 1 }
      end
    end
  end
end
