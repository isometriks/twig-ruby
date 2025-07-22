# frozen_string_literal: true

require 'active_support/testing/time_helpers'
require 'simplecov'
require 'simplecov-json'

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
])

SimpleCov.add_filter do |src_file|
  File.basename(src_file.filename) == 'base.rb'
end

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
  config.include(ActiveSupport::Testing::TimeHelpers)
end

require_relative '../lib/twig_ruby'
