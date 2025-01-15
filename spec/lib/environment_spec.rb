# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Environment do
  let(:templates) { { hello: 'Hello {{ name }}' } }
  let(:loader) { Twig::Loader::Array.new(templates) }
  let(:environment) { Twig::Environment.new(loader) }
end
