module Twig
  module Node
    module Expression
      class Base < Node::Base
        # @return [Expression::Base]
        def set_explicit_parentheses
          attributes[:with_parentheses] = true

          self
        end

        def explicit_parentheses?
          attributes.key?(:with_parentheses) && attributes[:with_parentheses]
        end
      end
    end
  end
end
