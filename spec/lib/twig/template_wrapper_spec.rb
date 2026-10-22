# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::TemplateWrapper do
  context 'when the parent template comes from a global' do
    let(:loader) do
      Twig::Loader::Hash.new({
        'template_wrapper/base.twig' => '{% block x %}{% endblock %}{% block y %}{% endblock %}',
        'template_wrapper/other.twig' => '{% block z %}{% endblock %}',
        'template_wrapper/index.twig' => '{% extends layout %}{% block x %}{% endblock %}',
      })
    end

    let(:environment) do
      Twig::Environment.new(loader, strict_variables: true).tap do |env|
        env.add_global(:layout, 'template_wrapper/base.twig')
      end
    end

    let(:wrapper) { environment.load('template_wrapper/index.twig') }

    it 'finds blocks through the parent' do
      expect(wrapper.block?('x')).to be(true)
      expect(wrapper.block?('y')).to be(true)
      expect(wrapper.block?('nope')).to be(false)
    end

    it 'lets the given context override the globals' do
      context = { layout: 'template_wrapper/other.twig' }

      expect(wrapper.block?('z', context)).to be(true)
      expect(wrapper.block?('y', context)).to be(false)
      expect(context).to eq({ layout: 'template_wrapper/other.twig' })
    end

    it 'lets the given context override a global registered with a string name' do
      environment = Twig::Environment.new(loader, strict_variables: true)
      environment.add_global('layout', 'template_wrapper/base.twig')
      wrapper = environment.load('template_wrapper/index.twig')

      expect(wrapper.block?('z', { layout: 'template_wrapper/other.twig' })).to be(true)
      expect(wrapper.block?('y', { 'layout' => 'template_wrapper/other.twig' })).to be(false)
    end
  end

  context 'when the wrapper comes from another environment' do
    let(:message) { /can only be used with the "Twig::Environment" that created it/ }
    let(:foreign) do
      Twig::Environment.new(Twig::Loader::Hash.new({
        'template_wrapper/foreign.twig' => '{% block content %}foreign content{% endblock %}' \
                                           '{% macro foo() %}foreign macro{% endmacro %}',
      }))
    end
    let(:foreign_wrapper) { foreign.load('template_wrapper/foreign.twig') }

    it 'unwraps only for the environment that created it' do
      expect(foreign_wrapper.unwrap(foreign)).to be_a(Twig::Template)
      expect { foreign_wrapper.unwrap(Twig::Environment.new(Twig::Loader::Hash.new({}))) }.
        to raise_error(Twig::Error::Runtime, message)
    end

    it 'is rejected by load and resolve_template' do
      environment = Twig::Environment.new(Twig::Loader::Hash.new({}))

      expect { environment.load(foreign_wrapper) }.to raise_error(Twig::Error::Runtime, message)
      expect { environment.resolve_template(['missing.twig', foreign_wrapper]) }.
        to raise_error(Twig::Error::Runtime, message)
    end

    it 'is accepted by the environment that created it' do
      expect(foreign.load(foreign_wrapper)).to be(foreign_wrapper)
    end

    {
      'include tag' => '{% include foreign %}',
      'include function' => '{{ include(foreign) }}',
      'include function fallback' => '{{ include(["missing.twig", foreign]) }}',
      'include_only function' => '{{ include_only(foreign) }}',
      'extends tag' => '{% extends foreign %}',
      'embed tag' => '{% embed foreign %}{% endembed %}',
      'import tag' => '{% import foreign as macros %}{{ macros.foo() }}',
      'from tag' => '{% from foreign import foo %}{{ foo() }}',
      'block function' => '{{ block("content", foreign) }}',
    }.each_with_index do |(usage, source), index|
      it "is rejected by the #{usage}" do
        name = "template_wrapper/foreign_usage_#{index}.twig"
        environment = Twig::Environment.new(Twig::Loader::Hash.new({ name => source }))

        expect { environment.load(name).render({ foreign: foreign_wrapper }) }.
          to raise_error(Twig::Error::Runtime, message)
      end
    end
  end
end
