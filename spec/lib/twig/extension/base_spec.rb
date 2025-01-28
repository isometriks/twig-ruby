# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Extension::Base do
  it 'provides default values' do
    expect([{}, {}]).to eq(subject.operators)
    expect({}).to eq(subject.filters)
    expect([]).to eq(subject.token_parsers)
  end
end
