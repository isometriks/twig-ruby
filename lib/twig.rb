require 'digest'

%w[
  .
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
    next if File.basename(file).inspect == 'base.rb'
    require file
  end
end

module Twig
end
