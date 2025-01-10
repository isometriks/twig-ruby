require 'digest'

%w[
  .
  error
  extension
  loader
  node
  node/expression
  node/expression/binary
  token_parser
].each do |directory|
  directory = __dir__ + "/twig/#{directory}/"
  require directory + 'base.rb' if File.file?(directory + 'base.rb')

  Dir[directory + '*.rb'].each do |file|
    next if %w[base.rb railtie.rb].include?(File.basename(file))
    require file
  end
end

# Railtie
require 'twig/railtie' if defined?(::Rails::Railtie)

module Twig
end
