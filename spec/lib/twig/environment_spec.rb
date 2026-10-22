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

  context 'when another process recompiles into a shared cache' do
    let(:cache_directory) { Dir.mktmpdir }
    let(:environment) { described_class.new(loader, cache: cache_directory, auto_reload: true) }
    let(:template) { 'recompiled_elsewhere.twig' }

    it 'renders the new source instead of its own stale copy' do
      now = Time.now.to_i
      write_template(template, 'Version one', mtime: Time.at(now - 60))
      expect(environment.load(template).render({})).to eq('Version one')

      # A test worker or a console picks up the edit first, and stamps its
      # cache entry later than the edit
      write_template(template, 'Version two', mtime: Time.at(now))
      pid = fork do
        allow(Process).to receive(:clock_gettime).and_call_original
        allow(Process).to receive(:clock_gettime).with(Process::CLOCK_REALTIME, :second).and_return(now + 5)
        other = described_class.new(loader, cache: cache_directory, auto_reload: true)
        exit!(other.load(template).render({}) == 'Version two')
      end
      _, status = Process.wait2(pid)
      expect(status).to be_success

      expect(environment).not_to receive(:render_ruby)
      expect(environment.load(template).render({})).to eq('Version two')
    end
  end

  context 'when auto reloading and nothing changes' do
    let(:environment) { described_class.new(loader, cache: false, auto_reload: true) }

    it 'compiles each template once even without a cache' do
      write_template('unchanged.twig', 'Same', mtime: Time.now - 60)

      expect(environment).to receive(:render_ruby).once.and_call_original
      3.times { expect(environment.load('unchanged.twig').render({})).to eq('Same') }
    end
  end

  { 'a filesystem cache' => 'dropped_cached', 'no cache' => 'dropped_uncached' }.each do |description, prefix|
    context "when a recompile with #{description} drops code" do
      let(:cache) { prefix == 'dropped_cached' && Dir.mktmpdir }
      let(:environment) { described_class.new(loader, cache:, auto_reload: true) }

      it 'no longer finds a deleted macro' do
        write_template("#{prefix}_macros.twig", '{% macro old() %}OLD{% endmacro %}', mtime: Time.now - 60)
        write_template("#{prefix}_page.twig", "{% import '#{prefix}_macros.twig' as m %}[{{ m.old() }}]")
        expect(environment.load("#{prefix}_page.twig").render({})).to eq('[OLD]')

        write_template("#{prefix}_macros.twig", '{% macro new() %}NEW{% endmacro %}')
        expect { environment.load("#{prefix}_page.twig").render({}) }.
          to raise_error(Twig::Error::Runtime, /"old"/)
      end

      it 'no longer extends the layout once extends is removed' do
        write_template("#{prefix}_layout.twig", '{% block title %}Layout title{% endblock %}')
        write_template("#{prefix}_child.twig", "{% extends '#{prefix}_layout.twig' %}", mtime: Time.now - 60)
        expect(environment.load("#{prefix}_child.twig").render({})).to eq('Layout title')

        write_template("#{prefix}_child.twig", "[{{ block('title') }}]")
        expect { environment.load("#{prefix}_child.twig").render({}) }.
          to raise_error(Twig::Error::Runtime, /"title"/)
      end
    end
  end

  context 'when a recompile replaces a template still rendering' do
    let(:environment) { described_class.new(loader, cache: false, auto_reload: true) }

    it 'finishes the render with the code it started with' do
      write_template('replaced_while_rendering.twig', 'Version one', mtime: Time.now - 60)
      template = environment.load('replaced_while_rendering.twig')

      write_template('replaced_while_rendering.twig', 'Version two')
      expect(environment.load('replaced_while_rendering.twig').render({})).to eq('Version two')
      expect(template.render({})).to eq('Version one')
    end
  end

  context 'when only a template used as a trait changes' do
    let(:environment) { described_class.new(loader, cache: Dir.mktmpdir, auto_reload: true) }

    it 'renders the new trait' do
      write_template('edited_trait.twig', '{% block title %}Trait one{% endblock %}', mtime: Time.now - 60)
      write_template('trait_user.twig', "{% use 'edited_trait.twig' %}{{ block('title') }}", mtime: Time.now - 60)
      expect(environment.load('trait_user.twig').render({})).to eq('Trait one')

      write_template('edited_trait.twig', '{% block title %}Trait two{% endblock %}')
      expect(environment.load('trait_user.twig').render({})).to eq('Trait two')
    end
  end

  context 'when another environment recompiles a template this one loaded' do
    def environment
      described_class.new(loader, cache: false, auto_reload: true)
    end

    it 'keeps rendering the code it compiled' do
      write_template('other_environment.twig', '{{ v }}', mtime: Time.now - 60)
      html = environment
      # Configured differently without changing its options, so both still
      # compile the template to the same class name
      text = environment.tap { |env| env.extension(Twig::Extension::Escaper).default_strategy = false }

      expect(html.load('other_environment.twig').render({ v: '<b>' })).to eq('&lt;b&gt;')
      expect(text.load('other_environment.twig').render({ v: '<b>' })).to eq('<b>')
      expect(html.load('other_environment.twig').render({ v: '<b>' })).to eq('&lt;b&gt;')
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

          # Returns nothing, like PHP's CacheInterface::load
          Twig.module_eval(@entries[key])
          nil
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
