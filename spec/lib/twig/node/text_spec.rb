# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Node::Text do
  describe '#blank?' do
    {
      " \t\r\n" => true,
      "\xEF\xBB\xBF" => true,
      "\xEF\xBB\xBF \n" => true,
      '' => false,
      'foo' => false,
      ' foo ' => false,
      "\xEF\xBB\xBFfoo" => false,
      " \xEF\xBB\xBF" => false,
      # Like PHP's ctype_space, only ASCII whitespace counts, not NBSP or the ideographic space
      "\u00A0" => false,
      "\u3000\n" => false,
    }.each do |data, blank|
      it "is #{blank} for #{data.inspect}" do
        expect(described_class.new(data, 1).blank?).to be(blank)
      end
    end
  end
end
