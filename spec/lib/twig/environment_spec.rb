# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Twig::Environment do
  let(:directory) { Dir.mktmpdir }
  let(:loader) { Twig::Loader::Filesystem.new(directory, ['.']) }

  # Compiled classes are named after the template, so every example uses its
  # own template names to stay clear of the classes other examples defined.
  def write_template(name, contents, mtime: nil)
    path = File.join(directory, name)
    File.write(path, contents)
    FileUtils.touch(path, mtime:) if mtime
  end

  context 'when auto reloading without a cache' do
    let(:environment) { described_class.new(loader, cache: false, auto_reload: true) }

    it 'renders the new source once the template changes' do
      write_template('reload_without_cache.twig', 'Version one')
      expect(environment.load('reload_without_cache.twig').render({})).to eq('Version one')

      write_template('reload_without_cache.twig', 'Version two')
      expect(environment.load('reload_without_cache.twig').render({})).to eq('Version two')
    end
  end

  context 'when auto reloading with a filesystem cache' do
    let(:environment) { described_class.new(loader, cache: Dir.mktmpdir, auto_reload: true) }
    let(:template) { 'reload_with_cache.twig' }
    let(:cache_key) { environment.cache.generate_key(template, environment.template_class(template)) }

    it 'renders the new source once the template changes' do
      write_template(template, 'Version one', mtime: Time.now - 60)
      expect(environment.load(template).render({})).to eq('Version one')

      write_template(template, 'Version two')
      expect(environment.load(template).render({})).to eq('Version two')
      expect(File.read(cache_key)).to include('Version two')
    end
  end

  context 'when the template is saved while it compiles' do
    let(:environment) { described_class.new(loader, cache: Dir.mktmpdir, auto_reload: true) }
    let(:template) { 'saved_while_compiling.twig' }
    let(:cache_key) { environment.cache.generate_key(template, environment.template_class(template)) }

    before do
      allow(Process).to receive(:clock_gettime).and_call_original
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_REALTIME, :second).and_return(2_000)
      write_template(template, 'Version one', mtime: Time.at(1_000))

      saved = false
      allow(environment).to receive(:render_ruby).and_wrap_original do |original, name|
        original.call(name).tap do
          next if saved

          # The editor saves after the source was read but before the compiled
          # code reaches the cache
          saved = true
          write_template(template, 'Version two', mtime: Time.at(3_000))
        end
      end
    end

    it 'stamps the cache entry with the moment the source was read' do
      expect(environment.load(template).render({})).to eq('Version one')

      expect(environment.cache.timestamp(cache_key)).to eq(2_000)
    end

    it 'renders the saved source on the next load' do
      environment.load(template).render({})

      expect(environment.load(template).render({})).to eq('Version two')
    end
  end

  context 'when a test travels in time while compiling' do
    let(:cache_directory) { Dir.mktmpdir }
    let(:environment) { described_class.new(loader, cache: cache_directory, auto_reload: true) }
    let(:template) { 'compiled_while_travelling.twig' }

    it 'still sees edits made afterwards' do
      write_template(template, 'Version one', mtime: Time.now - 60)
      travel(8 * 86_400) { expect(environment.load(template).render({})).to eq('Version one') }

      write_template(template, 'Version two')
      other = described_class.new(loader, cache: cache_directory, auto_reload: true)

      expect(other.load(template).render({})).to eq('Version two')
      expect(environment.load(template).render({})).to eq('Version two')
    end
  end

  context 'with a cache whose write takes only key and content' do
    let(:cache) do
      Class.new(Twig::Cache::Base) do
        attr_reader :writes

        def initialize
          super
          @entries = {}
          @written_at = {}
          @writes = 0
        end

        def generate_key(_name, class_name)
          class_name
        end

        def write(key, content)
          @writes += 1
          @entries[key] = content
          @written_at[key] = Time.now.to_i
        end

        def load(key)
          return false unless @entries.key?(key)

          Twig.module_eval(@entries[key])
          true
        end

        def timestamp(key)
          @written_at.fetch(key, 0)
        end
      end.new
    end

    def environment
      described_class.new(loader, cache:, auto_reload: true)
    end

    it 'compiles the template into the cache' do
      write_template('two_argument_write.twig', 'Hello {{ name }}', mtime: Time.now - 60)

      expect(environment.load('two_argument_write.twig').render({ name: 'you' })).to eq('Hello you')
      expect(cache.writes).to eq(1)
    end

    it 'loads what another environment compiled' do
      write_template('two_argument_shared.twig', 'Shared', mtime: Time.now - 60)
      environment.load('two_argument_shared.twig')

      expect(environment.load('two_argument_shared.twig').render({})).to eq('Shared')
      expect(cache.writes).to eq(1)
    end
  end

  context 'when not auto reloading' do
    let(:environment) { described_class.new(loader, cache: false, auto_reload: false) }

    it 'keeps rendering the template it loaded first' do
      write_template('no_reload.twig', 'Version one')
      expect(environment.load('no_reload.twig').render({})).to eq('Version one')

      write_template('no_reload.twig', 'Version two')
      expect(environment.load('no_reload.twig').render({})).to eq('Version one')
    end
  end
end
