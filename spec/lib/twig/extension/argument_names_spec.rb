# frozen_string_literal: true

require 'spec_helper'

# Every argument of a core filter or function can be named as in Twig, where
# the name is the snake_case of the PHP parameter
RSpec.describe 'Twig argument names of the core callables' do
  # The template calling each callable with every argument named, and what
  # Twig PHP renders for it
  calls = {
    'date' => [
      '{{ "2020-01-02"|date(format: "-", timezone: "UTC") }}',
      '-',
    ],
    'replace' => [
      '{{ "a"|replace(from: {a: "b"}) }}',
      'b',
    ],
    'number_format' => [
      '{{ 1234.5|number_format(decimal: 1, decimal_point: ",", thousand_sep: " ") }}',
      '1 234,5',
    ],
    'round' => [
      '{{ 2.5|round(precision: 0, method: "floor") }}',
      '2',
    ],
    'convert_encoding' => [
      '{{ "a"|convert_encoding(to: "UTF-8", from: "ISO-8859-1") }}',
      'a',
    ],
    'striptags' => [
      '{{ "<b>a</b><i>b</i>"|striptags(allowable_tags: "<b>")|raw }}',
      '<b>a</b>b',
    ],
    'trim' => [
      '{{ "xax"|trim(character_mask: "x", side: "left") }}',
      'ax',
    ],
    'join' => [
      '{{ [1, 2, 3]|join(glue: ", ", and: " and ") }}',
      '1, 2 and 3',
    ],
    'split' => [
      '{{ "a,b,c"|split(delimiter: ",", limit: 2)|join("|") }}',
      'a|b,c',
    ],
    'sort' => [
      '{{ [3, 1, 2]|sort(arrow: (a, b) => a <=> b)|join }}',
      '123',
    ],
    'batch' => [
      '{{ [1, 2, 3]|batch(size: 2, fill: 0, preserve_keys: true)|map(r => r|join)|join(",") }}',
      '12,30',
    ],
    'column' => [
      '{{ [{"a": 1}, {"a": 2}]|column(name: "a")|join }}',
      '12',
    ],
    'filter' => [
      '{{ [1, 2, 3]|filter(arrow: v => v > 1)|join }}',
      '23',
    ],
    'map' => [
      '{{ [1, 2]|map(arrow: v => v * 2)|join }}',
      '24',
    ],
    'reduce' => [
      '{{ [1, 2]|reduce(arrow: (c, v) => c + v, initial: 10) }}',
      '13',
    ],
    'find' => [
      '{{ [1, 2, 3]|find(arrow: v => v > 1) }}',
      '2',
    ],
    'reverse' => [
      '{{ {a: 1, b: 2}|reverse(preserve_keys: true)|keys|join }}',
      'ba',
    ],
    'slice' => [
      '{{ [1, 2, 3, 4]|slice(start: 1, length: 2, preserve_keys: true)|keys|join }}',
      '12',
    ],
    'default' => [
      '{{ none|default(default: "d") }}',
      'd',
    ],
    'escape' => [
      '{{ "<"|escape(strategy: "html", charset: "UTF-8", autoescape: false) }}',
      '&lt;',
    ],
    'e' => [
      '{{ "<"|e(strategy: "html", charset: "UTF-8", autoescape: false) }}',
      '&lt;',
    ],
    'max' => [
      '{{ max(value: [1, 3]) }}',
      '3',
    ],
    'min' => [
      '{{ min(value: [1, 3]) }}',
      '1',
    ],
    'range' => [
      '{{ range(low: 1, high: 5, step: 2)|join }}',
      '135',
    ],
    'constant' => [
      '{{ constant(constant: "FOO", object: holder, check_defined: true) ? "yes" : "no" }}',
      'yes',
    ],
    'cycle' => [
      '{{ cycle(values: [1, 2], position: 3) }}',
      '2',
    ],
    'random' => [
      '{{ random(values: [5], max: 10) }}',
      '5',
    ],
    'date function' => [
      '{{ date(date: "2020-01-02", timezone: "UTC") is not null ? "ok" }}',
      'ok',
    ],
    'include' => [
      '{{ include(template: "t", variables: {a: 1}, with_context: false, ignore_missing: true) }}',
      '1',
    ],
    'include_only' => [
      '{{ include_only(template: "t", variables: {a: 1}, ignore_missing: true) }}',
      '1',
    ],
    'source' => [
      '[{{ source(name: "nope", ignore_missing: true) }}]',
      '[]',
    ],
    'template_from_string' => [
      '{{ include(template_from_string(template: "x{{ 1 }}", name: "n")) }}',
      'x1',
    ],
    'block' => [
      '{% block b %}B{% endblock %}{{ block(name: "b") }}',
      'BB',
    ],
    'attribute' => [
      '{{ attribute(variable: holder, attribute: "a", arguments: []) }}',
      'A',
    ],
  }.freeze

  # Callables without arguments to name, or whose only one collects any
  # number of them, and plural, singular and slug, which aren't in Twig's core
  unnamed = %w[
    abs capitalize first format invoke keys last length lower merge nl2br raw shuffle title upper url_encode
    values plural singular slug
  ].freeze

  # json_encode takes neither PHP's flags nor its depth
  unsupported = %w[json_encode].freeze

  let(:environment) do
    loader = Twig::Loader::Hash.new({ 'index' => '', 't' => '{{ a }}' })
    Twig::Environment.new(loader, { strict_variables: true }).tap do |env|
      env.add_extension(Twig::Extension::StringLoader.new)
    end
  end

  let(:holder) do
    stub_const('Holder', Class.new { def a = 'A' })
    stub_const('Holder::FOO', 'foo')
    Holder.new
  end

  calls.each do |name, (template, output)|
    it "names every argument of #{name}" do
      expect(environment.create_template(template).render({ holder:, none: nil })).to eq(output)
    end
  end

  # Twig fills an optional argument before a named one with its default, so
  # these are keyword parameters, which Ruby can skip
  {
    '{{ random(max: 0) }}' => '0',
    '{{ random(...{max: 0}) }}' => '0',
    '{{ "<"|e(charset: "UTF-8")|raw }}' => '&lt;',
    '{{ "<"|escape(charset: "UTF-8")|raw }}' => '&lt;',
    '{{ "<"|e("html", autoescape: true) }}' => '&lt;',
    '{{ "<"|e(autoescape: true)|raw }}' => '&lt;',
    '{{ "<"|escape(...{autoescape: true})|raw }}' => '&lt;',
    '{{ "<"|e("js", "UTF-8", true) }}' => '\\u003C',
  }.each do |template, output|
    it "skips the arguments before a named one in #{template}" do
      expect(environment.create_template(template).render).to eq(output)
    end
  end

  it "binds a spread name to the Twig name's parameter" do
    template = environment.create_template('{{ 1234.5|number_format(2, ...{thousandSep: " "}) }}')

    expect(template.render).to eq('1 234.50')
  end

  it 'still takes the Ruby names of the arguments Twig names differently' do
    template = environment.create_template(
      '{{ 1234.5|number_format(thousands_separator: " ") }}|{{ "<b>a</b>"|striptags(tags: "<b>")|raw }}|' \
      '{{ [1, 2, 3]|batch(count: 2)|length }}|{{ [{"a": 1}]|column(column: "a")|join }}|' \
      '{{ [1, 2]|map(proc: v => v * 2)|join }}|{{ [1, 2, 3]|join(and_glue: " and ") }}|' \
      '{{ constant("FOO", holder, defined_test: true) ? "yes" }}|' \
      '{{ include(template_from_string(string: "x")) }}'
    )

    expect(template.render({ holder: })).to eq('1 235|<b>a</b>|2|1|24|12 and 3|yes|x')
  end

  it 'covers every core filter and function' do
    covered = calls.keys.map { |name| name.delete_suffix(' function') } + unnamed + unsupported

    expect(environment.filters.keys + environment.functions.keys - %w[parent loop] - covered).to be_empty
  end
end
