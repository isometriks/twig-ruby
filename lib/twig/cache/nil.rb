# frozen_string_literal: true

module Twig
  module Cache
    class Nil < Cache::Base
      def generate_key(_name, _class_name)
        ''
      end

      def timestamp(_key)
        0
      end

      def write(_key, _content, mtime: nil); end
      def remove(_key); end

      # Nothing is ever cached, so there is never anything to load
      def load(_key)
        false
      end
    end
  end
end
