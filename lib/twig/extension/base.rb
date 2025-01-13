module Twig
  module Extension
    class Base
      def operators
        [{}, {}]
      end

      def filters
        {}
      end

      def token_parsers
        []
      end

      def helper_methods
        []
      end
    end
  end
end
