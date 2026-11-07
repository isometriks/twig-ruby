# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Extension::Base do
  it 'provides default values' do
    expect([]).to eq(subject.expression_parsers)
    expect([]).to eq(subject.filters)
    expect([]).to eq(subject.token_parsers)
    expect([]).to eq(subject.tests)
  end

  describe '#last_modified' do
    it 'is when the file defining the extension last changed' do
      file = File.expand_path('../../../../lib/twig/extension/core.rb', __dir__)

      expect(Twig::Extension::Core.new.last_modified).to eq(File.mtime(file).to_i)
    end

    it 'is zero for an extension without a source file' do
      expect(Class.new(described_class).new.last_modified).to eq(0)
    end
  end
end
