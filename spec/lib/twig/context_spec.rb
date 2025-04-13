# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Context do
  it 'accepts an initial state' do
    context = described_class.new({ initial: 'state' })

    expect('state').to eq(context[:initial])
  end

  it 'converts all keys to symbols' do
    context = described_class.new({ 'a' => 'b', 'c' => 'd' })
    expect(%i[a c]).to eq(context.keys)
  end

  it 'fetches keys as symbols' do
    context = described_class.new({ 'a' => 'b', 'c' => 'd' })
    expect('b').to eq(context[:a])
    expect('d').to eq(context[:c])
  end

  it 'removes context variables after popping state' do
    context = described_class.new({ initial: 'state' })
    context.push_stack
    context[:initial] = 'inside stack'
    context[:pushed] = 'pushed'

    expect('inside stack').to eq(context[:initial])
    expect('pushed').to eq(context[:pushed])

    context.pop_stack
  end

  it 'can clear all context from a scope' do
    context = described_class.new({ initial: 'state' })
    context.push_stack
    context.clear

    expect(context.length).to eq(0)
    expect(context.key?(:initial)).to be_falsey

    context[:initial] = '1 deep'
    expect(context[:initial]).to eq('1 deep')

    context.push_stack
    context.clear

    expect(context.length).to eq(0)
    expect(context.key?(:initial)).to be_falsey

    context[:initial] = '2 deep'
    expect(context[:initial]).to eq('2 deep')

    context.pop_stack
    expect(context[:initial]).to eq('1 deep')

    context.pop_stack

    expect(context.length).to eq(1)
    expect(context[:initial]).to eq('state')
  end

  it 'records single replacement for multiple assignments' do
    context = described_class.new({ initial: 'state' })
    context.push_stack
    context[:initial] = 'replacement'
    context[:initial] = 'another replacement'

    expect(context.instance_variable_get(:@stack)).to eq([{ remove: [], replace: { initial: 'state' } }])
  end
end
