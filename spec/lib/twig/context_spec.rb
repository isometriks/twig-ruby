# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Context do
  it 'accepts an initial state' do
    context = Twig::Context.new({ initial: 'state' })

    expect('state').to eq(context[:initial])
  end

  it 'converts all keys to symbols' do
    context = Twig::Context.new({ 'a' => 'b', 'c' => 'd' })
    expect(%i[a c]).to eq(context.keys)
  end

  it 'fetches keys as symbols' do
    context = Twig::Context.new({ 'a' => 'b', 'c' => 'd' })
    expect('b').to eq(context[:a])
    expect('d').to eq(context[:c])
  end

  it 'removes context variables after popping state' do
    context = Twig::Context.new({ initial: 'state' })
    context.push_stack
    context[:initial] = 'inside stack'
    context[:pushed] = 'pushed'

    expect('inside stack').to eq(context[:initial])
    expect('pushed').to eq(context[:pushed])

    context.pop_stack
  end
end
