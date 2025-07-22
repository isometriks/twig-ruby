# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/time'
require 'active_support/core_ext/date'
require 'active_support/core_ext/date_time'
require 'active_support/core_ext/string/output_safety'
require 'active_support/inflector'
require 'active_support/number_helper'
require 'digest'
require 'cgi'
require 'sanitize'
require 'json'

%w[
  .
  cache
  error
  extension
  loader
  runtime
  runtime_loader
  util
  node
  node/expression
  node/expression/binary
  node/expression/filter
  node/expression/unary
  node/expression/variable
  node/expression/test
  expression_parser
  expression_parser/prefix
  expression_parser/infix
  node_visitor
  token_parser
].each do |directory|
  directory = __dir__ + "/twig/#{directory}/"
  require "#{directory}base.rb" if File.file?("#{directory}base.rb")

  Dir["#{directory}*.rb"].each do |file|
    next if %w[base.rb engine.rb].include?(File.basename(file))

    require file
  end
end

Time.zone ||= 'UTC'

# Railtie
require 'twig/rails/engine' if defined?(Rails::Engine)

module Twig
  module Compiled
  end
end
