# frozen_string_literal: true

require 'simplecov'
require 'simplecov-json'
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
])
SimpleCov.start do
  enable_coverage :branch
end

module FixtureHelpers
  # @return [File]
  def file_fixture(path)
    File.new(File.join(fixture_path, path), 'r')
  end

  def fixture_path
    File.join(__dir__, 'fixtures')
  end
end

RSpec.configure do |config|
  config.include(FixtureHelpers)
end

require_relative '../lib/twig_ruby'
