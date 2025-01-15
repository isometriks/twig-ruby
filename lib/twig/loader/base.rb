# frozen_string_literal: true

module Twig
  module Loader
    class Base
      # @param [String] name
      # @return [Twig::Source]
      def get_source_context(name)
        raise 'get_source_context not implemented'
      end
    
      # @param [String] name
      # @return [String]
      def get_cache_key(name)
        raise 'get_cache_key not implemented'
      end
    
      # @param [String] name
      # @param [Integer] time
      # @return [Boolean]
      def fresh?(name, time)
        raise 'fresh? not implemented'
      end
    
      # @param [String] name
      # @return [Boolean]
      def exists?(name)
        raise 'exists? not implemented'
      end
    end
  end
end
