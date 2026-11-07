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
end
