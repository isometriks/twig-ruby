module Twig
  module Node
    class Text < Node::Base
      # @param [String] data
      # @param [Integer] lineno
      def initialize(data, lineno = 0)
        super({}, { data: }, lineno)
      end

      def compile(compiler)
        compiler.
          write('yield ').
          string(attributes[:data]).
          raw("\n")
      end
    end
  end
end
