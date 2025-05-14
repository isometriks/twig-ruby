# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Environment do
  let(:templates) { { 'index.twig': template } }
  let(:loader) { Twig::Loader::Array.new(templates) }
  let(:environment) { Twig::Environment.new(loader).tap { |env| env.add_extension(extension) } }

  context 'when there are dynamic callables' do
    let(:extension) do
      Class.new(Twig::Extension::Base) do
        def filters
          [
            Twig::TwigFilter.new('dynamic_*_filter', lambda { |name, value|
              "#{name}-#{value}-#{name}"
            }),
          ]
        end

        def functions
          [
            Twig::TwigFunction.new('dynamic_*_function', lambda { |name, value|
              "#{name}-#{value}-#{name}"
            }),
          ]
        end

        def tests
          [
            Twig::TwigTest.new('dynamic_*_test', lambda { |name, value|
              name == value
            }),
          ]
        end
      end.new
    end

    context 'when there is a dynamic filter' do
      let(:template) { '{{ "world"|dynamic_hello_filter }}' }

      it 'renders the dynamic filter with proper arguments' do
        expect(environment.load('index.twig').render).to eq('hello-world-hello')
      end
    end

    context 'when there is a dynamic function' do
      let(:template) { '{{ dynamic_hello_function("world") }}' }

      it 'renders the dynamic function with proper arguments' do
        expect(environment.load('index.twig').render).to eq('hello-world-hello')
      end
    end

    context 'when there is a dynamic test' do
      let(:template) { '{{ "world" is dynamic_world_test }}' }

      it 'renders the dynamic test with proper arguments' do
        expect(environment.load('index.twig').render).to eq('true')
      end
    end
  end

  context 'when the string loader extension is added' do
    let(:extension) { Twig::Extension::StringLoader.new }
    let(:template) { '{{ include(template_from_string("{{ \'Hello World!\' }}")) }}' }

    it 'renders the template from a string' do
      expect(environment.load('index.twig').render).to eq('Hello World!')
    end
  end
end
