# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/twig/rails/escaping_strategy'

RSpec.describe 'Template#default_escape_strategy' do
  # Compiled class names derive from the template name, so every example
  # uses its own names to stay clear of the classes other examples defined.
  def environment(templates, autoescape)
    Twig::Environment.new(Twig::Loader::Hash.new(templates), autoescape:, cache: false)
  end

  {
    'escape_strategy/guessed_html.html.twig' => %i[name html],
    'escape_strategy/guessed_js.js.twig' => %i[name js],
    'escape_strategy/guessed_none.txt.twig' => [:name, false],
    'escape_strategy/forced_html.js.twig' => %i[html html],
    'escape_strategy/forced_string.html.twig' => ['css', :css],
    'escape_strategy/disabled.html.twig' => [false, false],
  }.each do |name, (autoescape, expected)|
    it "is #{expected.inspect} for #{name} with autoescape #{autoescape.inspect}" do
      twig = environment({ name => '{{ value }}' }, autoescape)

      expect(twig.load(name).default_escape_strategy).to eq(expected)
    end
  end

  it 'follows a strategy picked by a callable' do
    twig = environment(
      { 'escape_strategy/mailer.text.twig' => '{{ value }}' },
      ->(name) { Twig::Rails::EscapingStrategy.guess(name) }
    )

    expect(twig.load('escape_strategy/mailer.text.twig').default_escape_strategy).to be(false)
  end

  ["'js'", 'false'].each do |tag|
    it "is not changed by an autoescape #{tag} tag" do
      name = "escape_strategy/autoescape_#{tag.delete("'")}.html.twig"
      twig = environment({ name => "{% autoescape #{tag} %}{{ value }}{% endautoescape %}" }, :name)

      expect(twig.load(name).default_escape_strategy).to eq(:html)
    end
  end

  it 'describes the body and not what the template renders' do
    twig = environment({
      'escape_strategy/inherits.html.twig' => "{% extends 'escape_strategy/inherited.txt.twig' %}",
      'escape_strategy/inherited.txt.twig' => '{{ value }}',
    }, :name)
    template = twig.load('escape_strategy/inherits.html.twig')

    expect(template.default_escape_strategy).to eq(:html)
    expect(template.render({ value: '<b>' })).to eq('<b>')
  end

  it 'is exposed by embedded templates with the strategy of their template' do
    twig = environment({
      'escape_strategy/index.js.twig' =>
        "{% embed 'escape_strategy/layout.html.twig' %}{% block content %}{{ value }}{% endblock %}{% endembed %}",
      'escape_strategy/layout.html.twig' => '{% block content %}{% endblock %}',
    }, :name)

    compiled = twig.load_and_compile('escape_strategy/index.js.twig')

    expect(compiled.scan(/def default_escape_strategy\n\s*:js\n/).length).to eq(2)
  end

  it 'is false for a template compiled without it' do
    template = Class.new(Twig::Template).new(environment({}, :name))

    expect(template.default_escape_strategy).to be(false)
  end
end
