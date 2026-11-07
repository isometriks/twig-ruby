# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::ExpressionParser::ExpressionParsers do
  def unary(precedence)
    Twig::ExpressionParser::Prefix::Unary.new(Twig::Node::Expression::Unary::Neg, '!!', precedence)
  end

  it 'accepts a precedence from 0 to 512' do
    parsers = described_class.new([unary(0), unary(512)])

    expect(parsers.by_name(:prefix, '!!').precedence).to eq(512)
  end

  [-1, 513, 600].each do |precedence|
    it "rejects a precedence of #{precedence}" do
      expect { described_class.new([unary(precedence)]) }.
        to raise_error(ArgumentError, "Precedence for \"!!\" must be between 0 and 512, got #{precedence}.")
    end
  end

  it 'rejects an extension operator outside the range' do
    extension = Class.new(Twig::Extension::Base) do
      define_method(:expression_parsers) do
        [Twig::ExpressionParser::Prefix::Unary.new(Twig::Node::Expression::Unary::Neg, '!!', 600)]
      end
    end
    environment = Twig::Environment.new(Twig::Loader::Hash.new({}))
    environment.add_extension(extension.new)

    expect { environment.expression_parsers }.
      to raise_error(ArgumentError, 'Precedence for "!!" must be between 0 and 512, got 600.')
  end

  it 'keeps every built-in operator in range' do
    environment = Twig::Environment.new(Twig::Loader::Hash.new({}))

    precedences = environment.expression_parsers.to_enum(:each).map(&:precedence)

    expect(precedences).to all(be_between(0, 512))
  end
end
