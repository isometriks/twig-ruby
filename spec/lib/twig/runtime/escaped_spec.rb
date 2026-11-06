# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Runtime::Escaped do
  let(:escaper) { Twig::Runtime::Escaper.new('UTF-8') }
  let(:escaped) { escaper.escape('a b', :html_attr) }

  it 'is an html_safe SafeBuffer that remembers its strategy' do
    expect(escaped).to be_a(ActiveSupport::SafeBuffer).and(be_html_safe)
    expect(escaped.strategy).to eq(:html_attr)
    expect(described_class.new('a').strategy).to eq(:html)
  end

  it 'is safe for the strategy that produced it and the ones it implies' do
    expect(escaped).to be_safe_for(:html_attr).and(be_safe_for(:html)).and(be_safe_for(:html_attr_relaxed))
    expect(escaped).not_to be_safe_for(:js)
    expect(described_class.new('a', :html_attr_relaxed)).to be_safe_for(:html)
    expect(described_class.new('a', :html_attr_relaxed)).not_to be_safe_for(:html_attr)
    expect(described_class.new('a', :html)).not_to be_safe_for(:html_attr)
  end

  it 'keeps its strategy when copied' do
    expect(escaped.dup.strategy).to eq(:html_attr)
    expect(escaped.to_s).to be(escaped)
  end

  context 'when something is added to it' do
    it 'escapes an unsafe string for html, and is then only safe for html' do
      result = escaped + '<i>' # rubocop:disable Style/StringConcatenation

      expect(result).to eq('a&#x20;b&lt;i&gt;')
      expect(result).to be_a(described_class).and(be_html_safe)
      expect(result.strategy).to eq(:html)
      expect(escaped.strategy).to eq(:html_attr)
    end

    it 'keeps its strategy for output escaped for it or Markup' do
      expect((escaped + escaper.escape('c d', :html_attr)).strategy).to eq(:html_attr)
      expect((escaped + '<i>'.html_safe).strategy).to eq(:html_attr)
      expect((escaped + nil.to_s.html_safe).strategy).to eq(:html_attr)
    end

    it 'is only safe for html after output escaped for another strategy' do
      expect((escaped + escaper.escape('c d', :html)).strategy).to eq(:html)
      expect((escaped + escaper.escape('c d', :js)).strategy).to eq(:html)
    end

    it 'changes its strategy when changed in place' do
      [
        ->(s) { s << '<' },
        ->(s) { s.concat('<') },
        ->(s) { s.insert(0, '<') },
        ->(s) { s.prepend('<') },
        ->(s) { s.replace('<') },
        ->(s) { s[0] = '<' },
        ->(s) { s.safe_concat('<') },
      ].each do |change|
        copy = escaped.dup
        change.call(copy)

        expect(copy).to be_html_safe
        expect(copy.strategy).to eq(:html)
      end
    end

    it 'is escaped for html by %, and only safe for html' do
      result = described_class.new('%s', :js) % '<'

      expect(result).to eq('&lt;')
      expect(result).to be_a(described_class)
      expect(result.strategy).to eq(:html)
    end
  end

  it 'is only safe for html when sliced, rather than becoming Markup' do
    [escaped[0, 3], escaped.slice(0, 3), escaped.chr, escaped.dup.slice!(0, 3)].each do |part|
      expect(part).to be_a(described_class).and(be_html_safe)
      expect(part.strategy).to eq(:html)
    end

    copy = escaped.dup
    copy.slice!(0, 3)

    expect(copy.strategy).to eq(:html)
  end

  it 'keeps its strategy when repeated' do
    result = escaped * 2

    expect(result).to eq('a&#x20;ba&#x20;b')
    expect(result.strategy).to eq(:html_attr)
  end

  it 'is a plain string after an unsafe method, which is escaped again' do
    result = escaped.upcase

    expect(result).to be_an_instance_of(String)
    expect(escaper.escape(result, :html_attr, nil, true)).to eq('A&amp;&#x23;X20&#x3B;B')
  end

  it 'is no longer html_safe when changed in place by an unsafe method' do
    copy = escaped.dup
    copy.upcase!

    expect(copy).not_to be_html_safe
    expect(escaper.escape(copy, :html_attr, nil, true)).to eq('A&amp;&#x23;X20&#x3B;B')
  end

  it 'is Markup when marked html_safe, like the raw filter does' do
    expect(escaped.html_safe).to be_an_instance_of(ActiveSupport::SafeBuffer)
  end
end
