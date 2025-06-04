# frozen_string_literal: true

module Twig
  module Extension
    class Base
      def expression_parsers
        []
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

      def tests
        []
      end

      def node_visitors
        []
      end

      private

      def static(method)
        self.class.method(method)
      end

      def runtime(klass, method)
        [:runtime, klass, method]
      end
    end
  end
end
