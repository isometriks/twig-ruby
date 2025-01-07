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
    end
  end
end
