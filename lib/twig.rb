require 'digest'

require_relative 'twig/environment'
require_relative 'twig/compiler'
require_relative 'twig/lexer'
require_relative 'twig/source'
require_relative 'twig/template'
require_relative 'twig/token'
require_relative 'twig/token_stream'
require_relative 'twig/parser'
require_relative 'twig/token_parser/base'
require_relative 'twig/extension_set'
require_relative 'twig/extension/base'
require_relative 'twig/callable'
require_relative 'twig/twig_filter'
require_relative 'twig/loader/base'
require_relative 'twig/node/base'
require_relative 'twig/expression_parser'
require_relative 'twig/node/expression/expression'
require_relative 'twig/node/expression/binary/binary'

%w[
  extension
  loader
  node
  node/expression
  node/expression/binary
  token_parser
].each do |directory|
  Dir[__dir__ + "/twig/#{directory}/*.rb"].each do |file|
    require file
  end
end

module Twig
end
