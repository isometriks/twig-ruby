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
