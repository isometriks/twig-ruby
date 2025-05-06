# frozen_string_literal: true

module Twig
  module RuntimeLoader
    class Base
      # @return [Object, nil]
      def load(klass)
        raise NotImplementedError
      end
    end
  end
end
