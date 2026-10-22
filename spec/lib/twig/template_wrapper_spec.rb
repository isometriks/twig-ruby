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
end
