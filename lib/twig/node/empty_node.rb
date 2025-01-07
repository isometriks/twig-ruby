module Twig
  module Node
    class EmptyNode < Node::Base
      def initialize(lineno = 0)
        super({}, {}, lineno)
      end
    end
  end
end
