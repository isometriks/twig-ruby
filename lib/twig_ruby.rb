# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/date'
require 'active_support/core_ext/date_time'
require 'active_support/core_ext/string/output_safety'
require 'active_support/inflector'
require 'active_support/number_helper'
require 'digest'
require 'cgi'

%w[
  .
  cache
  error
  extension
  loader
  runtime
  runtime_loader
  node
  node/expression
  node/expression/binary
  node/expression/filter
  node/expression/unary
  node/expression/variable
  node/expression/test
  node_visitor
  token_parser
].each do |directory|
  directory = __dir__ + "/twig/#{directory}/"
  require "#{directory}base.rb" if File.file?("#{directory}base.rb")

  Dir["#{directory}*.rb"].each do |file|
    next if %w[base.rb railtie.rb].include?(File.basename(file))

    require file
  end
end

# Railtie
require 'twig/railtie' if defined?(Rails::Railtie)

module Twig
  module Compiled
  end
end
