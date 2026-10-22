# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Source do
  describe '#column' do
    let(:source) { described_class.new("foo\nbarbaz\nqux", 'index') }

    it 'gives the 1-based column on the first line' do
      expect(source.column(0)).to eq(1)
      expect(source.column(2)).to eq(3)
    end

    it 'starts a new line after "\n"' do
      expect(source.column(4)).to eq(1)
      expect(source.column(7)).to eq(4)
    end

    it 'starts a new line after "\r\n" and "\r"' do
      expect(described_class.new("foo\r\nbar", 'index').column(5)).to eq(1)
      expect(described_class.new("foo\rbar", 'index').column(4)).to eq(1)
    end

    it 'counts bytes before the offset' do
      expect(described_class.new('é{{ 1__2 }}', 'index').column(5)).to eq(7)
    end

    it 'gives nil for an unknown offset' do
      expect(source.column(-1)).to be_nil
      expect(source.column(nil)).to be_nil
    end
  end
end
