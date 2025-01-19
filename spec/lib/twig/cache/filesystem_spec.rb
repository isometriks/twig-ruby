# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Twig::Cache::Filesystem do
  let(:directory) { Dir.mktmpdir }
  let(:cache) { described_class.new(directory) }
  let(:class_name) { 'Twig::TestFilesystemCache' }
  let(:cache_key) { cache.generate_key('filesystem.rb', class_name) }

  it 'writes cache files to disk' do
    cache.write(cache_key, 'Hello World!')

    expect(File.file?(cache_key)).to be_truthy
  end

  it 'loads a class from cache' do
    cache.write(cache_key, "class #{class_name}; end")
    cache.load(cache_key)

    expect(Twig.const_defined?(class_name)).to be_truthy
  end

  it 'gets last modified time from cache from' do
    cache.write(cache_key, 'Hello World!')
    expect(cache.timestamp(cache_key)).to be > 0

    FileUtils.touch(cache_key, mtime: 1_234_567_890)
    expect(cache.timestamp(cache_key)).to eq(1_234_567_890)
  end
end
