# frozen_string_literal: true

require 'spec_helper'

# The expected values are what PHP's json_encode gives
RSpec.describe Twig::Util::PhpJson do
  it 'escapes / and characters outside ASCII by default' do
    value = { 'c' => "\u00E9/<>&'\"\\\x1F\u2028\u{1F600}\t", 'k/' => [1, [], { 'x' => nil }] }

    expect(described_class.encode(value)).to eq(
      %q({"c":"\u00e9\/<>&'\"\\\\\u001f\u2028\ud83d\ude00\t","k\/":[1,[],{"x":null}]})
    )
  end

  it 'escapes <, >, &, apostrophes and quotes as hex for the JSON_HEX flags' do
    expect(described_class.encode(%q(<>&'"), 15)).to eq(%q("\u003C\u003E\u0026\u0027\u0022"))
  end

  it 'leaves / and characters outside ASCII for the JSON_UNESCAPED flags' do
    expect(described_class.encode("\u00E9/", 64 | 256)).to eq("\"\u00E9/\"")
    expect(described_class.encode("\u2028", 256)).to eq(%q("\u2028"))
    expect(described_class.encode("\u2028", 256 | 2048)).to eq("\"\u2028\"")
  end

  it 'pretty prints like PHP for JSON_PRETTY_PRINT' do
    expect(described_class.encode({ 'a' => [1, { 'b' => 2 }, []], 'e' => {} }, 128)).
      to eq(%({\n    "a": [\n        1,\n        {\n            "b": 2\n        },\n        []\n    ],\n    "e": {}\n}))
  end

  it 'gives false for what it cannot encode, like PHP' do
    expect(described_class.encode("a\xFFb")).to be(false)
    expect(described_class.encode(Float::NAN)).to be(false)
  end
end
