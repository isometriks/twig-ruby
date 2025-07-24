# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Loader::Filesystem do
  let(:first_loader) { Twig::Loader::Hash.new({ 'first.twig' => 'first' }) }
  let(:second_loader) { Twig::Loader::Hash.new({ 'second.twig' => 'second' }) }
  let(:chain_loader) { Twig::Loader::Chain.new([first_loader, second_loader]) }

  it 'gets templates from chain loader with multiple array loaders' do
    expect(chain_loader.get_source_context('first.twig').code).to eq('first')
    expect(chain_loader.get_source_context('second.twig').code).to eq('second')
  end

  it 'knows templates exist from chain loader with multiple array loaders' do
    expect(chain_loader.exists?('first.twig')).to be_truthy
    expect(chain_loader.exists?('second.twig')).to be_truthy
  end

  it 'knows templates are fresh from chain loader with multiple array loaders' do
    expect(chain_loader.fresh?('first.twig', 0)).to be_truthy
    expect(chain_loader.fresh?('second.twig', 0)).to be_truthy
  end
end
