# frozen_string_literal: true

require 'spec_helper'

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

  context 'when a directory does not exist' do
    it 'raises when adding or prepending it' do
      expect { loader.add_path('missing') }.to raise_error(Twig::Error::Loader, /"missing" directory does not exist/)
      expect { loader.prepend_path('missing', 'theme') }.to raise_error(Twig::Error::Loader, /does not exist/)
      expect(loader.paths('theme')).to eq([])
    end

    it 'adds it without checking when asked to' do
      loader.add_path('missing', check: false)
      loader.prepend_path('missing_first', check: false)
      loader.add_path('missing', 'theme', check: false)

      expect(loader.paths).to eq(%w[missing_first loader missing])
      expect(loader.paths('theme')).to eq(['missing'])
      expect(loader.get_source_context(template).code).to eq("Hello World!\n")
      expect(loader.exists?('@theme/base.html.twig')).to be(false)
    end
  end

  it 'strips trailing separators from paths' do
    loader.add_path('loader/theme/')
    loader.add_path('missing\\', check: false)
    loader.add_path('/', check: false)

    expect(loader.paths).to eq(['loader', 'loader/theme', 'missing', '/'])
  end

  it 'keeps an empty path, which is the root path' do
    loader = described_class.new(fixture_path, [''])

    expect(loader.paths).to eq([''])
    expect(loader.exists?('loader/theme/base.html.twig')).to be(true)
  end

  context 'when the loader has a @theme namespace' do
    let(:template) { '@theme/base.html.twig' }

    before do
      loader.add_path(File.join(fixture_path, '/loader/theme'), 'theme')
    end

    it 'reads file from namespace' do
      expect(loader.get_source_context(template).code).to eq("theme/base.html.twig\n")
    end

    context 'when a path is prepended to @theme namespace' do
      before do
        loader.prepend_path('loader/theme_prepend', 'theme')
      end

      it 'gives precedence to prepended path' do
        expect(loader.get_source_context(template).code).to eq("theme_prepend/base.html.twig\n")
      end
    end
  end
end
