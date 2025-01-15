# frozen_string_literal: true

module Twig
  module Node
    class Empty < Node::Base
      def initialize(lineno = 0)
        super({}, {}, lineno)
      end
    end
  end
end
