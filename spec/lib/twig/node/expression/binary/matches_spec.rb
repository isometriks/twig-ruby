# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::Matches do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "12345" matches "/\\d+/" }}
        {{ a matches "/\\d+/" }}
        {{ "HELLO" matches "/[a-z]+/i" }}
        {{ "cat" matches "~a~" }}
        {{ "CAT" matches "#a#i" }}
        {{ "cat" matches "{a}" }}
        {{ "a/b" matches "/a\\/b/" }}
        {{ "ba" matches "/a/A" ? "KO" : "OK" }}
        {{ lines matches "/a.b/" ? "KO" : "OK" }}
        {{ lines matches "/a.b/s" }}
        {{ "cat" matches pattern }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        true
        true
        true
        true
        true
        true
        true
        OK
        OK
        true
        true
      OUTPUTS
    end

    let(:locals) { { a: 456, lines: "a\nb", pattern: '(c)' } }
  end

  context 'with a subject that is not valid UTF-8' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        <<~INPUTS
          {{ subject matches "/a/" }}
          {{ subject matches "/^.a$/" }}
          {{ bytes matches "/a/" }}
        INPUTS
      end

      let(:outputs) do
        <<~OUTPUTS
          true
          true
          true
        OUTPUTS
      end

      let(:locals) { { subject: "\xFFa".dup.force_encoding(Encoding::UTF_8), bytes: "\xFFa".b } }
    end

    it 'raises when the u modifier asks for UTF-8' do
      environment = Twig::Environment.new(Twig::Loader::Hash.new({ 'index' => '{{ subject matches "/a/u" }}' }))

      expect do
        environment.load('index').render({ subject: "\xFFa".dup.force_encoding(Encoding::UTF_8) })
      end.to raise_error(Twig::Error::Runtime, %r{Regexp "/a/u" passed to "matches" failed: Malformed UTF-8})
    end
  end

  context 'with a constant pattern that has no delimiters' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ "12345" matches "\d+" }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /Regexp "\\d\+" passed to "matches" is not valid: Delimiter must not be alphanumeric/ }
    end
  end

  context 'with a constant pattern that has an unknown modifier' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ "a" matches "/a/b/" }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { %r{Regexp "/a/b/" passed to "matches" is not valid: Unknown modifier 'b'} }
    end
  end

  context 'with a dynamic pattern that has no ending delimiter' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ "a" matches "(" ~ "a" }}' }
      let(:error) { Twig::Error::Runtime }
      let(:message) { /Regexp "\(a" passed to "matches" is not valid: No ending matching delimiter '\)'/ }
    end
  end
end
