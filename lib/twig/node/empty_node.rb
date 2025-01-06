module Twig
  module Node
    class EmptyNode < Node
      def initialize(lineno = 0)
        super({}, {}, lineno)
      end
    end
  end
end
