# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'rbconfig'
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

  it 'reports a missing entry as not loaded' do
    expect(cache.load(cache_key)).to be(false)
  end

  it 'keeps the old entry readable while a new one is written' do
    cache.write(cache_key, 'Version one')
    seen_while_writing = nil

    allow(File).to receive(:write).and_wrap_original do |original, *args|
      original.call(*args).tap { seen_while_writing = File.read(cache_key) }
    end
    cache.write(cache_key, 'Version two')

    expect(seen_while_writing).to eq('Version one')
    expect(File.read(cache_key)).to eq('Version two')
  end

  it 'leaves no temporary files behind' do
    cache.write(cache_key, 'Version one')
    cache.write(cache_key, 'Version two')

    expect(Dir.children(File.dirname(cache_key))).to eq([File.basename(cache_key)])
  end

  it 'leaves the entry untouched when the new one cannot be put in place' do
    cache.write(cache_key, 'Version one')

    allow(File).to receive(:rename).and_raise(Errno::EACCES)
    expect { cache.write(cache_key, 'Version two') }.to raise_error(Errno::EACCES)

    expect(File.read(cache_key)).to eq('Version one')
    expect(Dir.children(File.dirname(cache_key))).to eq([File.basename(cache_key)])
  end

  it 'gets last modified time from cache from' do
    cache.write(cache_key, 'Hello World!')
    expect(cache.timestamp(cache_key)).to be > 0

    FileUtils.touch(cache_key, mtime: 1_234_567_890)
    expect(cache.timestamp(cache_key)).to eq(1_234_567_890)
  end

  it 'stamps an entry with the time it is given' do
    cache.write(cache_key, 'Hello World!', mtime: 1_234_567_890)

    expect(cache.timestamp(cache_key)).to eq(1_234_567_890)
  end

  it 'creates missing directories with nothing but the gem required' do
    # A fresh process, since the spec run itself may already have loaded
    # FileUtils through something else.
    script = <<~RUBY
      require 'twig_ruby'
      key = File.join(ARGV[0], 'nested', 'entry.rb')
      Twig::Cache::Filesystem.new(ARGV[0]).write(key, 'Hello World!')
      print File.read(key)
    RUBY
    lib = File.expand_path('../../../../lib', __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, '-I', lib, '-e', script, directory)

    expect([output, status.success?]).to eq(['Hello World!', true])
  end
end
