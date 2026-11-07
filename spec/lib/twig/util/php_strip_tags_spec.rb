# frozen_string_literal: true

require 'spec_helper'

# The expected values are what PHP's strip_tags gives
RSpec.describe Twig::Util::PhpStripTags do
  {
    '<a title=">">x</a>' => %w[x x],
    'a<b' => %w[a a],
    '<<b>>x' => %w[x x],
    'x< y' => ['x< y', 'x< y'],
    '<!-- a > b -->c' => %w[c c],
    '<?xml version="1.0"?>d' => %w[d d],
    '<p onclick="a">t</p>' => ['t', '<p onclick="a">t</p>'],
    '<br />x' => ['x', '<br />x'],
  }.each do |string, (stripped, allowed)|
    it "strips #{string.inspect} like PHP" do
      expect(described_class.call(string)).to eq(stripped)
      expect(described_class.call(string, '<P><br>')).to eq(allowed)
      expect(described_class.call(string, %w[p br])).to eq(allowed)
    end
  end

  it 'keeps a byte that is not valid in the encoding of the string' do
    expect(described_class.call("<b>a\xFF</b>")).to eq("a\xFF").and(have_attributes(encoding: Encoding::UTF_8))
  end
end
