# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Runtime::Escaper do
  let(:escaper) { described_class.new('UTF-8') }
  let(:strategies) { %i[html js url css html_attr html_attr_relaxed] }

  it 'raises for an unknown strategy' do
    expect { escaper.escape('<"alert{}">', :unknown) }.to raise_error(
      Twig::Error::Runtime,
      'Invalid escaping strategy "unknown" (valid ones: "html", "js", "url", "css", "html_attr", "html_attr_relaxed").'
    )
  end

  it 'returns an html_safe string as is when autoescaping for html' do
    string = '<b>'.html_safe

    expect(escaper.escape(string, :html, autoescape: true)).to be(string)
  end

  # Like Twig, which returns a Markup as is under autoescape
  it 'returns an html_safe string as is when autoescaping for any strategy' do
    string = '<b c>'.html_safe

    strategies.each do |strategy|
      expect(escaper.escape(string, strategy, autoescape: true)).to be(string)
    end
  end

  it 'escapes an html_safe string when not autoescaping' do
    expect(escaper.escape('a b'.html_safe, :html_attr)).to eq('a&#x20;b')
  end

  it 'returns what it escapes as Escaped for the strategy' do
    strategies.each do |strategy|
      escaped = escaper.escape('a b', strategy)

      expect(escaped).to be_a(Twig::Runtime::Escaped).and(be_html_safe)
      expect(escaped.strategy).to eq(strategy)
    end

    expect(escaper.escape('a', 'js').strategy).to eq(:js)
  end

  # Twig's escape returns a plain string, which autoescaping escapes again
  it 'escapes output escaped for html again when autoescaping for another strategy' do
    expect(escaper.escape(escaper.escape('a b'), :html_attr, autoescape: true)).to eq('a&#x20;b')
    expect(escaper.escape(escaper.escape('<'), :js, autoescape: true)).to eq('\u0026lt\u003B')
    expect(escaper.escape(escaper.escape('<', :js), :html_attr, autoescape: true)).to eq('&#x5C;u003C')
  end

  it 'returns escaped output as is when autoescaping for a strategy it is safe for' do
    {
      html: %i[html],
      js: %i[js],
      css: %i[css],
      url: %i[url],
      html_attr: %i[html_attr html html_attr_relaxed],
      html_attr_relaxed: %i[html_attr_relaxed html],
    }.each do |strategy, safe_for|
      escaped = escaper.escape('a b<', strategy)

      strategies.each do |autoescape|
        result = escaper.escape(escaped, autoescape, autoescape: true)

        if safe_for.include?(autoescape)
          expect(result).to be(escaped)
        else
          expect(result).to eq(escaper.escape(escaped.to_str, autoescape))
        end
      end
    end
  end

  it 'escapes javascript' do
    expect(escaper.escape('<"alert{}">', :js)).to eq('\u003C\u0022alert\u007B\u007D\u0022\u003E')
  end

  it 'escapes html attributes' do
    expect(escaper.escape('onclick:alert(1)', :html_attr)).to eq('onclick&#x3A;alert&#x28;1&#x29;')
  end

  # Twig checks the first byte, so only the one-byte DEL is replaced
  it 'escapes C1 control characters in html attributes as hex entities' do
    %i[html_attr html_attr_relaxed].each do |strategy|
      expect(escaper.escape("a\u0085b", strategy)).to eq('a&#x0085;b')
      expect(escaper.escape("\u0080\u009F", strategy)).to eq('&#x0080;&#x009F;')
      expect(escaper.escape("a\u007Fb", strategy)).to eq('a&#xFFFD;b')
    end
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

  # Like Twig, which uses rawurlencode (RFC 3986) where CGI.escape gives +
  it 'escapes urls with a space as %20' do
    expect(escaper.escape("a b+c~*'()!/?&=", :url)).to eq('a%20b%2Bc~%2A%27%28%29%21%2F%3F%26%3D')
  end

  it 'escapes urls with a space as %20 when autoescaping' do
    environment = Twig::Environment.new(Twig::Loader::Hash.new({
      'index' => "{{ x|e('url') }}|{% autoescape 'url' %}{{ y }}{% endautoescape %}|{{ x|url_encode }}",
    }))

    expect(environment.load('index').render({ 'x' => 'a b~c*d', 'y' => '<b c>' })).
      to eq('a%20b~c%2Ad|%3Cb%20c%3E|a%20b~c%2Ad')
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
