# frozen_string_literal: true

module Twig
  module Node
    # Marks a node that captures the output of its children instead of
    # displaying it (not to be confused with Node::Capture).
    module Capturing; end
  end
end
