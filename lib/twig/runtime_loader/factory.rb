# frozen_string_literal: true

module Twig
  module RuntimeLoader
    class Factory < Base
      def initialize(map)
        super()

        @map = map.transform_keys do |klass|
          klass.is_a?(Class) ? klass.name : klass
        end
      end

      def load(klass)
        klass = klass.name if klass.is_a?(Class)

        return nil unless @map.key?(klass)

        @map[klass].call
      end
    end
  end
end
