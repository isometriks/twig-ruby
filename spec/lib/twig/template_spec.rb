# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Template do
  let(:loader) { Twig::Loader::Array.new({ 'template.twig' => template }) }
  let(:environment) { Twig::Environment.new(loader) }

  context 'when a block is missing' do
    let(:template) { '{{ block("missing") }}' }

    it 'raises an exception for a missing block' do
      expect do
        environment.load_template('template.twig').render
      end.to raise_error(Twig::Error::Runtime, /Block 'missing' on template/)
    end
  end
end
