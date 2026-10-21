# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Runtime::Escaper do
  let(:escaper) { described_class.new('UTF-8') }

  it 'returns the same string if no matching escaper' do
    expect(escaper.escape('<"alert{}">', :unknown)).to eq('<"alert{}">')
  end

  it 'escapes javascript' do
    expect(escaper.escape('<"alert{}">', :js)).to eq('\u003C\u0022alert\u007B\u007D\u0022\u003E')
  end

  it 'escapes html attributes' do
    expect(escaper.escape('onclick:alert(1)', :html_attr)).to eq('onclick&#x3A;alert&#x28;1&#x29;')
  end

  describe ':html_attr_relaxed strategy' do
    it 'preserves colons, at-signs, and brackets' do
      expect(escaper.escape('v:bind@click[0]', :html_attr_relaxed)).to eq('v:bind@click[0]')
    end

    it 'still escapes equals, quotes, and angle brackets' do
      expect(escaper.escape('v:bind@click="foo"', :html_attr_relaxed)).to eq('v:bind@click&#x3D;&quot;foo&quot;')
    end

    it 'escapes ampersands' do
      expect(escaper.escape('a&b', :html_attr_relaxed)).to eq('a&amp;b')
    end

    it 'escapes spaces and parentheses' do
      expect(escaper.escape('on click(x)', :html_attr_relaxed)).to eq('on&#x20;click&#x28;x&#x29;')
    end

    it 'preserves alphanumeric and basic safe chars' do
      expect(escaper.escape('hello-world_123,test.ok', :html_attr_relaxed)).to eq('hello-world_123,test.ok')
    end

    it 'escapes multi-byte characters' do
      result = escaper.escape("\u00E9", :html_attr_relaxed)
      expect(result).to eq('&#x00E9;')
    end

    it 'replaces undefined HTML characters with replacement character' do
      expect(escaper.escape("\x01", :html_attr_relaxed)).to eq('&#xFFFD;')
    end

    it 'raises on invalid UTF-8' do
      expect { escaper.escape("Hello \x80 world!", :html_attr_relaxed) }.to raise_error(
        Twig::Error::Runtime,
        /not a valid UTF-8 string/
      )
    end
  end

  it 'escapes css' do
    expect(escaper.escape('div > a { color: blue; }', :css)).to eq(
      'div\20 \3E \20 a\20 \7B \20 color\3A \20 blue\3B \20 \7D '
    )
  end

  it 'raises errors with invalid utf8 strings' do
    %i[js html_attr css].each do |type|
      expect { escaper.escape("Hello \x80 world!", type) }.to raise_error(
        Twig::Error::Runtime,
        /not a valid UTF-8 string/
      )
    end
  end
end
