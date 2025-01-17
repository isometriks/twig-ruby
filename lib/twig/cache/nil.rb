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

      def write(_key, _content); end
      def load(_key); end
      def remove(_key); end
    end
  end
end
