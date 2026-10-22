# frozen_string_literal: true

module Twig
  module Cache
    class Base
      # @param [String] name
      # @param [String] class_name
      def generate_key(name, class_name)
        raise NotImplementedError
      end

      # @param [String] key
      # @param [String] content
      # @param [Integer, nil] mtime When the compiled source was read, which
      #   #timestamp should report for this entry from then on. Optional: a
      #   cache whose write takes only key and content, like PHP's, still works
      def write(key, content, mtime: nil)
        raise NotImplementedError
      end

      # Evaluates the entry, defining its template class. The environment
      # checks for the class afterwards, so the return value isn't relied on.
      #
      # @param [String] key
      # @return [Boolean]
      def load(key)
        raise NotImplementedError
      end

      # @param [String] key
      # @return [Integer]
      def timestamp(key)
        raise NotImplementedError
      end
    end
  end
end
