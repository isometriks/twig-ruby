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

      def globals
        {}
      end

      # When the extension's code last changed, so templates compiled before
      # then are compiled again when auto reloading. Defaults to the mtime of
      # the file defining the extension's class; override it when the
      # extension's compiled output depends on other files too.
      #
      # @return [Integer]
      def last_modified
        file, = Object.const_source_location(self.class.name) if self.class.name

        file && File.file?(file) ? File.mtime(file).to_i : 0
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
