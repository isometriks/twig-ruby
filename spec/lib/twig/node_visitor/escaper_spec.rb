# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::NodeVisitor::Escaper do
  context 'when html escaped output is autoescaped for another strategy' do
    let(:environment) { Twig::Environment.new(Twig::Loader::Hash.new({})) }

    {
      "{% autoescape 'html_attr' %}<div class={{ v|e }}>{% endautoescape %}" =>
        '<div class=x&#x20;onmouseover&#x3D;alert&#x28;1&#x29;>',
      "{% autoescape 'js' %}{{ v|e }}{% endautoescape %}" => 'x\u0020onmouseover\u003Dalert\u00281\u0029',
      "{% autoescape 'js' %}{{ v|e('js') }}{% endautoescape %}" => 'x\u0020onmouseover\u003Dalert\u00281\u0029',
    }.each do |source, output|
      it "escapes it again in #{source.inspect}" do
        expect(environment.create_template(source).render({ v: 'x onmouseover=alert(1)' })).to eq(output)
      end
    end
  end

  # Twig prints a Markup as is under every strategy. Set captures, macro
  # results, raw output and html_safe values such as a Rails SafeBuffer are
  # this gem's Markup. The outputs are Twig's.
  context 'when Markup is autoescaped for any strategy' do
    let(:environment) { Twig::Environment.new(Twig::Loader::Hash.new({}), strict_variables: true) }

    {
      "{% autoescape 'js' %}{% set s %}a b{% endset %}{{ s }}{% endautoescape %}" => 'a b',
      "{% autoescape 'js' %}{% set s %}{{ x }}{% endset %}{{ s }}{% endautoescape %}" => 'a\u0020b',
      "{% autoescape 'css' %}{% set s %}{{ x }}{% endset %}{{ s }}{% endautoescape %}" => 'a\20 b',
      "{% autoescape 'html_attr' %}<div class={% set s %}{{ x }}{% endset %}{{ s }}>{% endautoescape %}" =>
        '<div class=a&#x20;b>',
      "{% autoescape 'html_attr' %}{% set s %}<b>{{ x }}</b>{% endset %}{{ s }}{% endautoescape %}" =>
        '<b>a&#x20;b</b>',
      '{% macro m(v) %}<i>{{ v }}</i>{% endmacro %}' \
      "{% autoescape 'html_attr' %}{% set y = _self.m(x) %}{{ y }}{% endautoescape %}" => '<i>a b</i>',
      "{% macro m(v) %}{{ v }}{% endmacro %}{% autoescape 'js' %}{% set y = _self.m(x) %}{{ y }}{% endautoescape %}" =>
        'a b',
      "{% autoescape 'html_attr' %}{% set y = x|raw %}{{ y }}{% endautoescape %}" => 'a b',
      "{% autoescape 'html_attr' %}{% set y = (x|e)|raw %}{{ y }}{% endautoescape %}" => 'a b',
    }.each do |source, output|
      it "prints it as is in #{source.inspect}" do
        expect(environment.create_template(source).render({ x: 'a b' })).to eq(output)
      end
    end

    %w[js css html_attr html_attr_relaxed url].each do |strategy|
      it "prints an html_safe value as is under #{strategy}" do
        template = environment.create_template("{% autoescape '#{strategy}' %}{{ x }}{% endautoescape %}")

        expect(template.render({ x: '<b c>'.html_safe })).to eq('<b c>')
      end
    end

    it 'prints a SafeBuffer concatenation as is under js' do
      template = environment.create_template("{% autoescape 'js' %}{{ x }}{% endautoescape %}")

      buffer = '<b>'.html_safe + '<i>' # rubocop:disable Style/StringConcatenation

      expect(template.render({ x: buffer })).to eq('<b>&lt;i&gt;')
    end

    it 'prints a capture as is in a template escaped by its name' do
      environment = Twig::Environment.new(
        Twig::Loader::Hash.new({ 'i.js' => '{% set y %}{{ x }}{% endset %}{{ y }}' }), autoescape: :name
      )

      expect(environment.load('i.js').render({ x: 'a b' })).to eq('a\u0020b')
    end
  end

  # Twig's escape filter returns a plain string, so a value stored from it is
  # escaped again. The outputs are Twig's.
  context 'when stored escaped output is autoescaped for a strategy it is not safe for' do
    let(:environment) { Twig::Environment.new(Twig::Loader::Hash.new({}), strict_variables: true) }

    [
      ["{% set y = v|e %}{% autoescape 'html_attr' %}{{ y }}{% endautoescape %}", 'a b<', 'a&#x20;b&amp;lt&#x3B;'],
      [
        "{% set y = v|e('html_attr_relaxed') %}{% autoescape 'html_attr' %}{{ y }}{% endautoescape %}",
        'a:b c', 'a&#x3A;b&amp;&#x23;x20&#x3B;c'
      ],
      ["{% autoescape 'html_attr' %}{{ v|e|trim }}{% endautoescape %}", ' a b< ', 'a&#x20;b&amp;lt&#x3B;'],
      ["{% autoescape 'html_attr' %}{{ (v|e)|slice(0, 3) }}{% endautoescape %}", 'a b<', 'a&#x20;b'],
      ["{% autoescape 'html_attr' %}{{ (v|e)|first }}{% endautoescape %}", '<b', '&amp;'],
      ["{% autoescape 'html_attr' %}{{ (v|e)|last }}{% endautoescape %}", 'b<', '&#x3B;'],
    ].each do |source, value, output|
      it "escapes it again in #{source.inspect}" do
        expect(environment.create_template(source).render({ v: value })).to eq(output)
      end
    end
  end

  context 'when stored escaped output is autoescaped for a strategy it is safe for' do
    let(:environment) { Twig::Environment.new(Twig::Loader::Hash.new({}), strict_variables: true) }

    # Unlike Twig, which escapes the plain string again
    {
      "{% set y = v|e('html_attr') %}{{ y }}" => 'a&#x20;b&lt;',
      "{% set y = v|e('html_attr') %}{% autoescape 'html_attr_relaxed' %}{{ y }}{% endautoescape %}" => 'a&#x20;b&lt;',
      "{% set y = v|e('js') %}{% autoescape 'js' %}{{ y }}{% endautoescape %}" => 'a\u0020b\u003C',
    }.each do |source, output|
      it "prints it as is in #{source.inspect}" do
        expect(environment.create_template(source).render({ v: 'a b<' })).to eq(output)
      end
    end
  end

  context 'when a compilation error happens inside an autoescape tag' do
    let(:loader) do
      Twig::Loader::Hash.new({
        'escaper_reset/broken.html' => '{% autoescape false %}{{ foo|failing|nl2br }}{% endautoescape %}',
        'escaper_reset/index.html' => '{{ foo }}',
        'escaper_reset/index.txt' => '{{ foo }}',
      })
    end

    let(:environment) do
      Twig::Environment.new(loader, autoescape: :name).tap do |env|
        env.add_extension(Class.new(Twig::Extension::Base) do
          def filters
            [
              Twig::TwigFilter.new('failing', ->(value) { value }, {
                is_safe_callback: ->(_args) { raise 'Unable to compute the safety of the filter.' },
              }),
            ]
          end
        end.new)
      end
    end

    it 'does not affect the escaping of the next template' do
      expect { environment.load('escaper_reset/broken.html') }.to raise_error(/Unable to compute the safety/)

      expect(environment.load('escaper_reset/index.txt').render({ foo: '<br>' })).to eq('<br>')
      expect(environment.load('escaper_reset/index.html').render({ foo: '<br>' })).to eq('&lt;br&gt;')
    end
  end
end
