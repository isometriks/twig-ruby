# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::TokenStream do
  describe '#expect' do
    def expect_error(value, expected_value = nil)
      tokens = [Twig::Token.new(Twig::Token::NUMBER_TYPE, value, 1, 0), Twig::Token.new(Twig::Token::EOF_TYPE, '', 1)]

      described_class.new(tokens, Twig::Source.new('0', 'index')).expect(Twig::Token::NAME_TYPE, expected_value)
    rescue Twig::Error::Syntax => e
      e.message.delete_suffix(' in "index" at line 1 column 1.')
    else
      raise 'A syntax error should have been raised.'
    end

    it 'shows a value that is truthy in PHP' do
      expect(expect_error(1)).to eq('Unexpected token "number" of value "1" ("name" expected)')
      expect(expect_error('a', 'b')).
        to eq('Unexpected token "number" of value "a" ("name" expected with value "b")')
    end

    it 'leaves out a value that is falsy in PHP' do
      [0, 0.0, '0', ''].each do |value|
        expect(expect_error(value)).to eq('Unexpected token "number" ("name" expected)')
      end

      expect(expect_error(1, '0')).to eq('Unexpected token "number" of value "1" ("name" expected)')
    end

    it 'leaves out a zero in a template' do
      environment = Twig::Environment.new(Twig::Loader::Hash.new({ 'index' => '{% for 0 in x %}{% endfor %}' }))

      expect { environment.load('index') }.to raise_error(
        Twig::Error::Syntax,
        'Only variables can be assigned to. Unexpected token "number" ("name" expected) in "index" at line 1 column 8.'
      )
    end
  end
end
