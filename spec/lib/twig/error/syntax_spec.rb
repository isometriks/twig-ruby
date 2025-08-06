# frozen_string_literal: true

require 'spec_helper'

describe Twig::Error::Syntax do
  describe '#initialize' do
    let(:message) { 'Syntax error message' }
    let(:lineno) { 25 }
    let(:source) { instance_double('Twig::Source', path: 'template.twig', name: 'template') }

    subject(:error) { described_class.new(message, lineno, source) }

    it 'inherits from Twig::Error::Base' do
      expect(error).to be_a(Twig::Error::Base)
    end

    it 'sets the error message' do
      expect(error.to_s).to include('Syntax error messag')
    end

    it 'sets the line number' do
      expect(error.lineno).to eq(lineno)
    end

    it 'sets the source context' do
      expect(error.source_context).to eq(source)
    end

    it 'includes the template name in the error message' do
      expect(error.to_s).to include('template')
    end

    it 'includes the line number in the error message' do
      expect(error.to_s).to include('line 25')
    end
  end

  describe 'with default parameters' do
    subject(:error) { described_class.new('Syntax error message') }

    it 'sets a default line number' do
      expect(error.lineno).to eq(-1)
    end

    it 'sets a default source context' do
      expect(error.source_context).to be_nil
    end

    it 'does not include line number in the error message' do
      expect(error.to_s).not_to include('line')
    end
  end
end
