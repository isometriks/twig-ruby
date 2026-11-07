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

  context 'when environments with different options share a cache' do
    let(:cache_directory) { Dir.mktmpdir }

    before { write_template('options.twig', '') }

    def environment(**)
      described_class.new(loader, cache: cache_directory, auto_reload: true, **)
    end

    it 'compiles the template separately for each' do
      write_template('shared_options.twig', '[{{ missing }}]', mtime: Time.now - 60)
      lenient = environment(strict_variables: false)
      strict = environment(strict_variables: true)

      expect(lenient.load('shared_options.twig').render({})).to eq('[]')
      expect(strict.template_class('shared_options.twig')).not_to eq(lenient.template_class('shared_options.twig'))
      expect { strict.load('shared_options.twig').render({}) }.to raise_error(Twig::Error::Runtime, /missing/)
    end

    it 'names the class after every option that changes the compiled code' do
      names = [
        environment, environment(debug: true), environment(strict_variables: true),
        environment(allow_helper_methods: true), environment(autoescape: false),
        environment(autoescape: ->(_name) { :html })
      ].map { |env| env.template_class('options.twig') }

      expect(names.uniq.length).to eq(6)
    end

    it 'escapes the template for each by its own autoescape option' do
      write_template('shared_autoescape.twig', '{{ v }}', mtime: Time.now - 60)
      html = environment(autoescape: :html)
      text = environment(autoescape: false)

      expect(html.load('shared_autoescape.twig').render({ v: '<b>' })).to eq('&lt;b&gt;')
      expect(text.load('shared_autoescape.twig').render({ v: '<b>' })).to eq('<b>')
      expect(html.load('shared_autoescape.twig').render({ v: '<b>' })).to eq('&lt;b&gt;')
    end

    it 'names an autoescape lambda after where it is defined' do
      strategy = -> { ->(name) { Twig::FileExtensionEscapingStrategy.guess(name) } }

      expect(environment(autoescape: strategy.call).template_class('options.twig')).
        to eq(environment(autoescape: strategy.call).template_class('options.twig'))
    end

    it 'names the class after the extensions' do
      env = environment
      before = env.template_class('options.twig')
      env.add_extension(Twig::Extension::Debug.new)

      expect(env.template_class('options.twig')).not_to eq(before)
    end

    it 'names the class after the gem version' do
      before = environment.template_class('options.twig')
      stub_const('Twig::VERSION', "#{Twig::VERSION}.1")

      expect(environment.template_class('options.twig')).not_to eq(before)
    end

    it 'names the class after the gem source' do
      before = environment.template_class('options.twig')
      allow(described_class).to receive(:source_signature).and_return('a different checkout')

      expect(environment.template_class('options.twig')).not_to eq(before)
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

  context 'when an extension changed after a template was compiled' do
    let(:cache_directory) { Dir.mktmpdir }

    before do
      stub_const('ChangingExtension', Class.new(Twig::Extension::Base) do
        def initialize(last_modified)
          super()
          @last_modified = last_modified
        end

        attr_reader :last_modified
      end)
    end

    def environment(extension_last_modified)
      described_class.new(loader, cache: cache_directory, auto_reload: true).tap do |env|
        env.add_extension(ChangingExtension.new(extension_last_modified))
      end
    end

    it 'compiles the template again' do
      write_template('extension_changed.twig', 'Compiled', mtime: Time.now - 60)
      expect(environment(0).load('extension_changed.twig').render({})).to eq('Compiled')

      changed = environment(Time.now.to_i + 60)
      expect(changed).to receive(:render_ruby).once.and_call_original
      expect(changed.load('extension_changed.twig').render({})).to eq('Compiled')
    end

    it 'loads the cache entry while the extension is older' do
      write_template('extension_unchanged.twig', 'Compiled', mtime: Time.now - 60)
      expect(environment(0).load('extension_unchanged.twig').render({})).to eq('Compiled')

      unchanged = environment(Time.now.to_i - 60)
      expect(unchanged).not_to receive(:render_ruby)
      expect(unchanged.load('extension_unchanged.twig').render({})).to eq('Compiled')
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

  context 'when copying an environment' do
    let(:environment) { described_class.new(Twig::Loader::Hash.new({})) }

    it 'rejects clone' do
      expect { environment.clone }.to raise_error(
        Twig::Error::Logic,
        'Cloning a Twig environment is not supported; build a new environment instead.'
      )
    end

    it 'rejects dup' do
      expect { environment.dup }.to raise_error(Twig::Error::Logic, /Cloning a Twig environment is not supported/)
    end
  end

  context 'with undefined callable callbacks' do
    let(:templates) do
      {
        'undefined_callbacks/filter.twig' => '{{ "x"|shout }}',
        'undefined_callbacks/function.twig' => '{{ greet("you") }}',
        'undefined_callbacks/test.twig' => '{{ 3 is odd_number ? "odd" : "even" }}',
        'undefined_callbacks/tag.twig' => '{% say "hey" %}',
        'undefined_callbacks/guard.twig' => '{% guard function boom %}yes{% else %}no{% endguard %}',
      }
    end
    let(:environment) { described_class.new(Twig::Loader::Hash.new(templates)) }

    let(:say_tag) do
      Class.new(Twig::TokenParser::Base) do
        def parse(token)
          expr = parser.parse_expression
          parser.stream.expect(Twig::Token::BLOCK_END_TYPE)

          Twig::Node::Print.new(expr, token.lineno)
        end

        def tag
          'say'
        end
      end
    end

    before do
      environment.register_undefined_filter_callback do |name|
        name == 'shout' && Twig::TwigFilter.new('shout', ->(value) { "#{value.upcase}!" })
      end
      environment.register_undefined_function_callback(lambda { |name|
        Twig::TwigFunction.new('greet', ->(who) { "hello #{who}" }) if name == 'greet'
      })
      environment.register_undefined_test_callback do |name|
        name == 'odd_number' && Twig::TwigTest.new('odd_number', lambda(&:odd?))
      end
      tag = say_tag
      environment.register_undefined_token_parser_callback { |name| tag.new if name == 'say' }
    end

    it 'asks the callbacks for names no extension defines' do
      expect(environment.filter('shout')).to be_a(Twig::TwigFilter)
      expect(environment.function('greet').name).to eq('greet')
      expect(environment.test('odd_number').name).to eq('odd_number')
      expect(environment.token_parser('say').tag).to eq('say')
    end

    it 'returns nil when no callback knows the name' do
      expect(environment.filter('does_not_exist')).to be_nil
      expect(environment.function('does_not_exist')).to be_nil
      expect(environment.test('does_not_exist')).to be_nil
      expect(environment.token_parser('does_not_exist')).to be_nil
    end

    it 'prefers what the extensions define' do
      environment.register_undefined_filter_callback { |name| Twig::TwigFilter.new(name, ->(_) { 'callback' }) }

      expect(environment.filter('upper').name).to eq('upper')
      expect(environment.filter('other').name).to eq('other')
    end

    it 'renders templates using them' do
      expect(environment.load('undefined_callbacks/filter.twig').render).to eq('X!')
      expect(environment.load('undefined_callbacks/function.twig').render).to eq('hello you')
      expect(environment.load('undefined_callbacks/test.twig').render).to eq('odd')
      expect(environment.load('undefined_callbacks/tag.twig').render).to eq('hey')
    end

    it 'treats a syntax error from a callback as undefined in a guard' do
      environment.register_undefined_function_callback { |_name| raise Twig::Error::Syntax, 'boom.' }

      expect(environment.load('undefined_callbacks/guard.twig').render).to eq('no')
    end

    it 'ignores a syntax error from a callback in the guarded body' do
      environment.register_undefined_filter_callback { |name| raise Twig::Error::Syntax, "nope #{name}." }
      environment.register_undefined_function_callback { |name| raise Twig::Error::Syntax, "nope #{name}." }
      environment.register_undefined_test_callback { |name| raise Twig::Error::Syntax, "nope #{name}." }
      templates = {
        'function' => '{% guard function boom %}{{ boom() }}{% else %}no{% endguard %}',
        'filter' => '{% guard filter boomf %}{{ 1|boomf }}{% else %}no{% endguard %}',
        'test' => '{% guard test boomt %}{{ 1 is boomt }}{% else %}no{% endguard %}',
        'two_word_test' => '{% guard test boom t %}{{ 1 is boom t }}{% else %}no{% endguard %}',
      }

      templates.each do |name, source|
        expect(environment.create_template(source, name).render).to eq('no')
      end
    end

    it 'raises a syntax error from a callback outside a guard' do
      environment.register_undefined_function_callback { |name| raise Twig::Error::Syntax, "nope #{name}." }

      expect { environment.create_template('{{ boom() }}').render }.
        to raise_error(Twig::Error::Syntax, /nope boom/)
    end

    it 'requires a callable or a block' do
      expect { environment.register_undefined_filter_callback }.
        to raise_error(ArgumentError, /undefined filter callback needs a callable or a block/)
      expect { environment.register_undefined_function_callback('nope') }.
        to raise_error(ArgumentError, /undefined function callback/)
      expect { environment.register_undefined_test_callback }.to raise_error(ArgumentError)
      expect { environment.register_undefined_token_parser_callback }.to raise_error(ArgumentError)
    end
  end

  describe '#add_global' do
    let(:extension) do
      Class.new(Twig::Extension::Base) do
        def globals
          { g: 'ext', 'k' => 'ext' }
        end
      end.new
    end

    let(:environment) do
      Twig::Environment.new(
        Twig::Loader::Hash.new(
          'index' => '{{ g }}|{{ k }}|{% with {} %}{{ g }}{% endwith %}|{{ include("i") }}',
          'i' => '{{ g }}'
        )
      ).tap { |env| env.add_extension(extension) }
    end

    it "wins over an extension's global with the other kind of key" do
      environment.add_global('g', 'env')
      environment.add_global(:k, 'env')

      expect(environment.load('index').render).to eq('env|env|env|env')
    end

    it 'changes an existing global after the first render' do
      environment.add_global('g', 'env')
      environment.load('index').render
      environment.add_global('g', 'changed')

      expect(environment.load('index').render).to eq('changed|ext|changed|changed')
    end

    it 'raises for a new global once a template has been compiled' do
      environment.load('index')

      expect { environment.add_global('new', 'x') }.
        to raise_error(
          Twig::Error::Logic,
          'Unable to add global "new" as the runtime or the extensions have already been initialized.'
        )
    end

    context 'when the template comes from a warm cache' do
      let(:cache_directory) { Dir.mktmpdir }
      let(:loader) { Twig::Loader::Hash.new('index' => '{{ g }}') }

      let(:environment) { Twig::Environment.new(loader, cache: cache_directory) }

      before do
        Twig::Environment.new(loader, cache: cache_directory).load('index').render
        environment.add_global('g', 'env')
      end

      after { FileUtils.rm_rf(cache_directory) }

      it 'raises for a new global once a template has been loaded' do
        expect(environment.load('index').render).to eq('env')

        expect { environment.add_global('new', 'x') }.
          to raise_error(
            Twig::Error::Logic,
            'Unable to add global "new" as the runtime or the extensions have already been initialized.'
          )
      end

      it 'keeps the globals once a template has been loaded' do
        environment.load('index').render

        expect(environment.globals).to equal(environment.globals)
      end
    end
  end
end
