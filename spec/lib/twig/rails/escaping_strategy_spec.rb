# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/twig/rails/escaping_strategy'

RSpec.describe Twig::Rails::EscapingStrategy do
  describe '.guess' do
    it 'does not escape the Rails plain text format' do
      expect(described_class.guess('app/views/mailer/welcome.text.twig')).to be(false)
      expect(described_class.guess('welcome.text')).to be(false)
    end

    it 'does not escape plain text with a locale or a variant' do
      expect(described_class.guess('mailer/welcome.en.text.twig')).to be(false)
      expect(described_class.guess('mailer/welcome.text+variant.twig')).to be(false)
      expect(described_class.guess('mailer/welcome.en.text+variant.twig')).to be(false)
    end

    it 'leaves txt to the core guess' do
      expect(described_class.guess('notes.txt.twig')).to be(false)
    end

    it 'escapes html, with or without a variant' do
      expect(described_class.guess('app/views/welcome/index.html.twig')).to eq(:html)
      expect(described_class.guess('welcome/index.html+phone.twig')).to eq(:html)
    end

    it 'keeps the core strategies for other formats' do
      expect(described_class.guess('data.json.twig')).to eq(:js)
      expect(described_class.guess('app.js+phone.twig')).to eq(:js)
      expect(described_class.guess('site.css.twig')).to eq(:css)
      expect(described_class.guess('partials/')).to eq(:html)
    end

    it 'only treats text as a format when it is the extension' do
      expect(described_class.guess('text/index.html.twig')).to eq(:html)
      expect(described_class.guess('help.text.html.twig')).to eq(:html)
      expect(described_class.guess('a+b/index.html.twig')).to eq(:html)
    end
  end

  context 'when used as the autoescape strategy' do
    let(:templates) do
      {
        'mailer/welcome.text.twig' => "{{ message }}\n",
        'mailer/welcome.html.twig' => "{{ message }}\n",
      }
    end

    let(:environment) do
      Twig::Environment.new(
        Twig::Loader::Hash.new(templates),
        autoescape: ->(name) { described_class.guess(name) }
      )
    end

    it 'renders a text template unescaped' do
      expect(environment.load('mailer/welcome.text.twig').render({ message: "It's <b>" })).to eq("It's <b>\n")
    end

    it 'still escapes an html template' do
      expect(environment.load('mailer/welcome.html.twig').render({ message: "It's <b>" })).
        to eq("It&#039;s &lt;b&gt;\n")
    end
  end
end
