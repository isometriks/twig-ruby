module Twig
  module Node
    module Expression
      class Expression < Node::Base
        # @return [Expression]
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
