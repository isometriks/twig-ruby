# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Loader::Filesystem do
  let(:template) { 'filesystem.html.twig' }
  let(:loader) { described_class.new(fixture_path, ['loader']) }

  it 'gets cache key without root path' do
    expect(loader.get_cache_key(template)).to eq('/loader/filesystem.html.twig')
  end

  it 'determines whether file is fresh or not' do
    expect(loader.fresh?(template, Time.now.to_i)).to be_truthy
    expect(loader.fresh?(template, 0)).to be_falsey
  end

  it "reads the file's contents from disk" do
    expect(loader.get_source_context(template).code).to eq("Hello World!\n")
  end
end
