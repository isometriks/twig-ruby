# frozen_string_literal: true

require 'active_support/core_ext/string/output_safety'
require 'digest'
require 'cgi'

%w[
  .
  cache
  error
  extension
  loader
  node
  node/expression
  node/expression/binary
  node/expression/unary
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
