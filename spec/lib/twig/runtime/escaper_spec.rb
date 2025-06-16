# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Runtime::Escaper do
  let(:escaper) { described_class.new('UTF-8') }

  it 'escapes javascript' do
    expect(escaper.escape('<"alert{}">', :js)).to eq('\u003C\u0022alert\u007B\u007D\u0022\u003E')
  end
end
