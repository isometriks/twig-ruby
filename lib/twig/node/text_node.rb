module Twig
  module Node
    class TextNode < Node
      # @param [String] data
      # @param [Integer] lineno
      def initialize(data, lineno)
        super([], { data: }, lineno)
      end
    end
  end
end
