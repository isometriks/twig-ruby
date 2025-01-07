module Twig
  module Node
    module Expression
      class Base < Node::Base
        # @return [Expression::Base]
        def set_explicit_parentheses
          attributes[:with_explicit_parentheses] = true

          self
        end

        def explicit_parentheses?
          attributes[:with_explicit_parentheses]
        end
      end
    end
  end
end
