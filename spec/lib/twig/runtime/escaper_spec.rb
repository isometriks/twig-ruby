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

  it 'raises errors with invalid utf8 strings' do
    %i[js html_attr].each do |type|
      expect { escaper.escape("Hello \x80 world!", type) }.to raise_error(
        Twig::Error::Runtime,
        /not a valid UTF-8 string/
      )
    end
  end
end
