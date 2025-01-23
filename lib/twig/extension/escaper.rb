# frozen_string_literal: true

module Twig
  module Extension
    class Escaper < Base
      def initialize(auto_escape)
        super()

        @auto_escape = auto_escape
      end

      def filters
        [
          TwigFilter.new('raw', nil, node_class: Node::Expression::Filter::Raw),
        ]
      end
    end
  end
end
