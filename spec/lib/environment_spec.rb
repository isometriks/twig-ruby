require 'spec_helper'

RSpec.describe Twig::Environment do
  let(:templates) { { hello: "Hello {{ name }}" } }
  let(:loader) { Twig::Loader::ArrayLoader.new(templates) }
  let(:environment) { Twig::Environment.new(loader) }

  it "does cool shit" do
    raise environment.load_and_compile(:hello).inspect
  end
end
