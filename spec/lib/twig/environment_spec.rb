# frozen_string_literal: true

require 'spec_helper'

describe Twig::Environment do
  let(:loader) { instance_double('Twig::Loader::Base') }
  let(:environment) { described_class.new(loader) }

  describe '#initialize' do
    it 'sets the loader' do
      expect(environment.loader).to eq(loader)
    end

    it 'sets default options' do
      expect(environment.charset).to eq('UTF-8')
      expect(environment.send(:instance_variable_get, :@strict_variables)).to be(false)
      expect(environment.send(:instance_variable_get, :@auto_reload)).to be(false)
    end

    it 'initializes the cache as Nil when cache option is false' do
      expect(environment.cache).to be_a(Twig::Cache::Nil)
    end

    it 'adds Core and Escaper extensions' do
      # Extensions are identified by their class name, not by string names
      extension_set = environment.send(:extension_set)
      expect(extension_set.instance_variable_get(:@extensions).values).to include(
        an_instance_of(Twig::Extension::Core),
        an_instance_of(Twig::Extension::Escaper)
      )
    end

    context 'with custom options' do
      let(:environment) do
        described_class.new(loader, {
          cache: '/tmp/cache',
          debug: true,
          charset: 'ISO-8859-1',
          strict_variables: true,
          autoescape: false,
          auto_reload: true,
          allow_helper_methods: true,
        })
      end

      it 'sets custom options' do
        expect(environment.charset).to eq('ISO-8859-1')
        expect(environment.send(:instance_variable_get, :@strict_variables)).to be(true)
        expect(environment.send(:instance_variable_get, :@auto_reload)).to be(true)
      end

      it 'sets cache to Filesystem when cache option is a string' do
        expect(environment.cache).to be_a(Twig::Cache::Filesystem)
      end
    end
  end

  describe '#template_class' do
    before do
      allow(loader).to receive(:get_cache_key).with('template_name').and_return('cache_key')
    end

    it 'generates a class name based on the template name' do
      result = environment.template_class('template_name')
      expect(result).to start_with('Compiled::Template_')
      expect(result).to include(Digest::SHA256.hexdigest('cache_key'))
    end

    it 'includes the index when provided' do
      result = environment.template_class('template_name', 1)
      expect(result).to end_with('___1')
    end
  end

  describe '#load' do
    let(:template_wrapper) { instance_double('Twig::TemplateWrapper') }
    let(:template) { instance_double('Twig::Template') }

    context 'when given a TemplateWrapper' do
      it 'returns the template wrapper' do
        # Need to stub the is_a? check to avoid calling get_cache_key on the loader
        allow(template_wrapper).to receive(:is_a?).with(Twig::TemplateWrapper).and_return(true)
        expect(environment.load(template_wrapper)).to eq(template_wrapper)
      end
    end

    context 'when given a template name' do
      before do
        allow(environment).to receive(:template_class).with('template_name').and_return('TemplateClass')
        allow(environment).to receive(:load_template).with('TemplateClass', 'template_name').and_return(template)
        allow(Twig::TemplateWrapper).to receive(:new).with(environment, template).and_return(template_wrapper)
      end

      it 'loads the template and wraps it' do
        expect(environment.load('template_name')).to eq(template_wrapper)
      end
    end
  end

  describe '#resolve_template' do
    let(:template_wrapper) { instance_double('Twig::TemplateWrapper') }

    context 'when given a single name' do
      it 'loads the template' do
        expect(environment).to receive(:load).with('template_name').and_return(template_wrapper)
        expect(environment.resolve_template('template_name')).to eq(template_wrapper)
      end
    end

    context 'when given a template wrapper' do
      it 'returns the template wrapper' do
        # Need to stub the is_a? check to avoid calling get_cache_key on the loader
        allow(template_wrapper).to receive(:is_a?).with(Array).and_return(false)
        allow(template_wrapper).to receive(:is_a?).with(Twig::TemplateWrapper).and_return(true)
        expect(environment.resolve_template(template_wrapper)).to eq(template_wrapper)
      end
    end

    context 'when given an array of names' do
      before do
        allow(loader).to receive(:exists?).with('template1').and_return(false)
        allow(loader).to receive(:exists?).with('template2').and_return(true)
      end

      it 'returns the first template that exists' do
        expect(environment).to receive(:load).with('template2').and_return(template_wrapper)
        expect(environment.resolve_template(%w[template1 template2])).to eq(template_wrapper)
      end

      it 'raises an error if no templates exist' do
        allow(loader).to receive(:exists?).with('template2').and_return(false)
        expect do
          environment.resolve_template(%w[template1 template2])
        end.to raise_error(Twig::Error::Loader)
      end
    end
  end

  describe '#add_extension' do
    let(:extension) { instance_double('Twig::Extension::Base') }

    it 'adds the extension to the extension set' do
      expect(environment.send(:extension_set)).to receive(:add).with(extension)
      environment.add_extension(extension)
    end
  end

  describe '#extension?' do
    before do
      allow(environment.send(:extension_set)).to receive(:has?).with('existing').and_return(true)
      allow(environment.send(:extension_set)).to receive(:has?).with('non_existing').and_return(false)
    end

    it 'returns true if the extension exists' do
      expect(environment.extension?('existing')).to be(true)
    end

    it 'returns false if the extension does not exist' do
      expect(environment.extension?('non_existing')).to be(false)
    end
  end

  describe '#extension' do
    let(:extension) { instance_double('Twig::Extension::Base') }

    it 'gets the extension from the extension set' do
      expect(environment.send(:extension_set)).to receive(:get).with('extension_name').and_return(extension)
      expect(environment.extension('extension_name')).to eq(extension)
    end
  end

  describe '#add_global' do
    it 'adds a global variable' do
      environment.add_global('variable_name', 'value')
      expect(environment.send(:instance_variable_get, :@globals)).to include('variable_name' => 'value')
    end
  end

  describe '#globals' do
    let(:extension_globals) { { 'ext_var' => 'ext_value' } }

    before do
      allow(environment.send(:extension_set)).to receive(:globals).and_return(extension_globals)
      environment.add_global('var', 'value')
    end

    it 'returns globals from extensions and added globals' do
      expect(environment.globals).to include('ext_var' => 'ext_value', 'var' => 'value')
    end
  end

  describe '#filter' do
    let(:filter) { instance_double('Twig::TwigFilter') }

    it 'gets the filter from the extension set' do
      expect(environment.send(:extension_set)).to receive(:filter).with('filter_name').and_return(filter)
      expect(environment.filter('filter_name')).to eq(filter)
    end
  end

  describe '#function' do
    let(:function) { instance_double('Twig::TwigFunction') }

    it 'gets the function from the extension set' do
      expect(environment.send(:extension_set)).to receive(:function).with('function_name').and_return(function)
      expect(environment.function('function_name')).to eq(function)
    end
  end

  describe '#test' do
    let(:test) { instance_double('Twig::TwigTest') }

    it 'gets the test from the extension set' do
      expect(environment.send(:extension_set)).to receive(:test).with('test_name').and_return(test)
      expect(environment.test('test_name')).to eq(test)
    end
  end

  describe '#token_parser' do
    let(:token_parser) { instance_double('Twig::TokenParser::Base') }

    it 'gets the token parser from the extension set' do
      expect(environment.send(:extension_set)).to receive(:token_parser).with('parser_name').and_return(token_parser)
      expect(environment.token_parser('parser_name')).to eq(token_parser)
    end
  end

  describe '#node_visitors' do
    let(:visitors) { [instance_double('Twig::NodeVisitor::Base')] }

    it 'gets the node visitors from the extension set' do
      expect(environment.send(:extension_set)).to receive(:node_visitors).and_return(visitors)
      expect(environment.node_visitors).to eq(visitors)
    end
  end

  describe '#cache=' do
    context 'when given a string' do
      it 'sets the cache to a Filesystem cache' do
        environment.cache = '/tmp/cache'
        expect(environment.cache).to be_a(Twig::Cache::Filesystem)
      end
    end

    context 'when given false' do
      it 'sets the cache to a Nil cache' do
        environment.cache = false
        expect(environment.cache).to be_a(Twig::Cache::Nil)
      end
    end

    context 'when given a Cache::Base instance' do
      let(:cache) { instance_double('Twig::Cache::Base') }

      it 'sets the cache to the given cache' do
        allow(cache).to receive(:class).and_return(Twig::Cache::Base)
        allow(Twig::Cache::Base).to receive(:<).with(Twig::Cache::Base).and_return(true)

        environment.cache = cache
        expect(environment.cache).to eq(cache)
      end
    end

    context 'when given an invalid value' do
      it 'raises an error' do
        expect { environment.cache = Object.new }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#debug?' do
    it 'returns the debug option value' do
      environment.instance_variable_set(:@options, { debug: true })
      expect(environment.debug?).to be(true)
    end
  end

  describe '#strict_variables?' do
    it 'returns the strict_variables value' do
      environment.instance_variable_set(:@strict_variables, true)
      expect(environment.strict_variables?).to be(true)
    end
  end

  describe '#allow_helper_methods?' do
    it 'returns the allow_helper_methods option value' do
      environment.instance_variable_set(:@options, { allow_helper_methods: true })
      expect(environment.allow_helper_methods?).to be(true)
    end
  end
end
