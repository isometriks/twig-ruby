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
end
