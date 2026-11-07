# frozen_string_literal: true

require 'spec_helper'

# The expected values are what Twig PHP renders for the same template
RSpec.describe Twig::Extension::Core do
  def render(template, context = {})
    environment = Twig::Environment.new(Twig::Loader::Hash.new({ 'index' => template }), strict_variables: true)

    environment.load('index').render(context)
  end

  describe 'nl2br' do
    it 'inserts <br /> before each \r\n, \n\r, \n and \r' do
      expect(render('{{ s|nl2br|raw }}', { 's' => "a\r\nb\rc\nd" })).to eq("a<br />\r\nb<br />\rc<br />\nd")
      expect(render('{{ s|nl2br|raw }}', { 's' => "\n\r\n\r\r\n\n\n" })).
        to eq("<br />\n\r<br />\n\r<br />\r\n<br />\n<br />\n")
    end

    it 'escapes before it inserts the breaks' do
      expect(render('{{ x|nl2br }}', { 'x' => "<b>\n" })).to eq("&lt;b&gt;<br />\n")
    end

    it 'gives an empty string for null' do
      expect(render('{{ null|nl2br }}')).to eq('')
    end
  end

  describe 'striptags' do
    it 'leaves the text between tags as it is, to be escaped once' do
      expect(render("{{ 'Tom & Jerry'|striptags }}")).to eq('Tom &amp; Jerry')
      expect(render("{{ 'a < b > c'|striptags }}")).to eq('a &lt; b &gt; c')
    end

    it 'adds no whitespace in place of tags or comments' do
      expect(render("{{ '<p>a <b>b</b></p><!-- c --><br/>d'|striptags }}")).to eq('a bd')
      expect(render('{{ s|striptags|raw }}', { 's' => "<p>a</p>\n<p>b</p>" })).to eq("a\nb")
    end

    it 'keeps the allowed tags, given as a string or as names' do
      expect(render("{{ '<p>a <b>b</b><br/></p>'|striptags('<b><br>')|raw }}")).to eq('a <b>b</b><br/>')
      expect(render("{{ '<p>a <b>b</b></p>'|striptags(['p'])|raw }}")).to eq('<p>a b</p>')
      expect(render("{{ '<b>x</b>'|striptags(allowable_tags='<b>')|raw }}")).to eq('<b>x</b>')
    end

    it 'removes processing instructions and declarations' do
      expect(render(%q({{ '<?php echo "a>b"; ?>c<!DOCTYPE html>d<?xml x ?>e'|striptags }}))).to eq('cde')
    end

    it 'gives an empty string for null' do
      expect(render('{{ null|striptags }}')).to eq('')
    end
  end

  describe 'title' do
    it 'upper-cases the first letter of each word and lower-cases the rest' do
      expect(render("{{ 'iPhone user'|title }}|{{ 'McDonald x'|title }}|{{ 'hello wORLD'|title }}")).
        to eq('Iphone User|Mcdonald X|Hello World')
    end

    it 'keeps underscores and hyphens, and starts a word after them' do
      expect(render("{{ 'a_b-c'|title }}|{{ 'hello-world foo_bar'|title }}")).to eq('A_B-C|Hello-World Foo_Bar')
    end

    it 'starts a word after a digit but not after an apostrophe' do
      expect(render(%q({{ "it's 1st o'neil"|title }}))).to eq('It&#039;s 1St O&#039;neil')
    end

    it 'title-cases other scripts' do
      expect(render("{{ 'élan ÉCOLE'|title }}|{{ 'ǆemal straße'|title }}|{{ 'ﬁx'|title }}")).
        to eq('Élan École|ǅemal Straße|Fix')
    end

    it 'gives an empty string for null' do
      expect(render('{{ null|title }}')).to eq('')
    end
  end

  describe 'format' do
    it 'formats like PHP sprintf' do
      expect(render(%q({{ '%e'|format(12345.678) }}|{{ "%'*10s"|format('hi') }}|{{ '%u'|format(-3) }}))).
        to eq('1.234568e+4|********hi|18446744073709551613')
      expect(render("{{ '%d'|format('12abc') }}|{{ '%d'|format(null) }}|{{ '%F'|format(1.5) }}")).
        to eq('12|0|1.500000')
      expect(render("{{ '%05.2f|%b|%x|%2$s %1$s'|format(3.14159, 5, 255) }}")).to eq('03.14|101|ff|5 3.14159')
      expect(render("{{ '%s %s'|format(1.0, true) }}|{{ '%s'|format(0.1 + 0.2) }}")).to eq('1 1|0.3')
      expect(render("{{ '%.2f'|format(2.675) }}|{{ '%.1f'|format(0.35) }}|{{ '%s'|format(7.05017039081155) }}")).
        to eq('2.67|0.3|7.0501703908115')
    end

    it 'gives an empty string for null' do
      expect(render('{{ null|format }}')).to eq('')
    end

    it 'raises when an argument is missing, like PHP' do
      expect { render("{{ '%s %s'|format('a') }}") }.to raise_error(
        Twig::Error::Runtime,
        'An exception has been thrown during the rendering of a template ' \
        '("3 arguments are required, 2 given") in "index" at line 1.'
      )
    end
  end

  describe 'number_format' do
    it 'rounds to tens, hundreds and so on for negative decimals' do
      expect(render('{{ 1250|number_format(-2) }}|{{ -1250.5|number_format(-1) }}|{{ 499|number_format(-3) }}')).
        to eq('1,300|-1,250|0')
    end

    it 'casts what is not a number to a float, like PHP' do
      expect(render("{{ true|number_format }}|{{ 'abc'|number_format }}|{{ '12abc'|number_format(1) }}")).
        to eq('1|0|12.0')
      expect(render("{{ null|number_format }}|{{ ''|number_format }}|{{ '1e3'|number_format }}")).to eq('0|0|1,000')
    end

    it 'uses the separators with no decimals' do
      expect(render("{{ 1250.5|number_format(0, ',', '.') }}|{{ 1250|number_format(-2, ',', '.') }}")).
        to eq('1.251|1.300')
      expect(render("{{ 1234567.891|number_format(2, '::', '--') }}")).to eq('1--234--567::89')
    end

    it 'drops the sign of a number that rounds to 0' do
      expect(render('{{ -0.4|number_format }}|{{ -0.004|number_format(2) }}')).to eq('0|0.00')
    end
  end

  describe 'url_encode' do
    it 'builds a query like http_build_query' do
      expect(render('{{ {a: null, b: true, c: false}|url_encode|raw }}')).to eq('b=1&c=0')
      expect(render('{{ {c: [1, 2]}|url_encode|raw }}|{{ {c: {d: "e"}}|url_encode|raw }}')).
        to eq('c%5B0%5D=1&c%5B1%5D=2|c%5Bd%5D=e')
      expect(render("{{ {a: 1.5, b: 1e20, 'x y': {'p q': [null, 'r s'], e: []}, 0: 'z'}|url_encode|raw }}")).
        to eq('a=1.5&b=1.0E%2B20&x%20y%5Bp%20q%5D%5B1%5D=r%20s&0=z')
      expect(render('{{ [1, "a b", [2]]|url_encode|raw }}|{{ {r: 1..2}|url_encode|raw }}')).
        to eq('0=1&1=a%20b&2%5B0%5D=2|r%5B0%5D=1&r%5B1%5D=2')
    end
  end

  describe 'replace' do
    it 'tries the longest key first at each position, like strtr' do
      expect(render("{{ 'aaa'|replace({'a': 'b', 'aa': 'c'}) }}")).to eq('cb')
      expect(render("{{ 'hello'|replace({'l': 'L', 'll': 'XX', 'hel': 'H'}) }}")).to eq('HLo')
    end

    it 'ignores an empty key, like strtr' do
      expect(render("{{ 'abc'|replace({'': 'x', 'b': 'y'}) }}|{{ 'x'|replace({'': 'y'}) }}")).to eq('ayc|x')
    end

    it 'converts the replacements like PHP' do
      expect(render("{{ 'a1'|replace({1: true, 'a': null}) }}")).to eq('1')
    end
  end

  describe 'date' do
    it 'reads a string of digits or @ and digits as a timestamp' do
      expect(render("{{ '1700000000'|date('%Y-%m-%d %H:%M:%S') }}|{{ '@1700000000'|date('%Y-%m-%d') }}")).
        to eq('2023-11-14 22:13:20|2023-11-14')
      expect(render("{{ '-86400'|date('%Y-%m-%d') }}|{{ '@1700000000.75'|date('%H:%M:%S.%6N') }}")).
        to eq('1969-12-31|22:13:20.750000')
    end

    it 'reads a float as a timestamp' do
      expect(render("{{ 1700000000.5|date('%Y-%m-%d %H:%M:%S.%L') }}")).to eq('2023-11-14 22:13:20.500')
    end

    it 'gives a timestamp in UTC when the timezone is false, like Twig' do
      expect(render("{{ '1700000000'|date('%H:%M %:z', false) }}|{{ 0|date('%H:%M %:z', false) }}")).
        to eq('22:13 +00:00|00:00 +00:00')
    end
  end
end
