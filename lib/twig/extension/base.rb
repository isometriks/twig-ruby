# frozen_string_literal: true

module Twig
  module Extension
    class Base
      def operators
        [{}, {}]
      end

      def filters
        []
      end

      def functions
        []
      end

      def token_parsers
        []
      end

      private

      def static(method)
        self.class.method(method)
      end
    end
  end
end
