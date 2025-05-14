# frozen_string_literal: true

module Twig
  module Runtime
    class Context < Hash
      def initialize(initial_context = {})
        super()

        merge!(initial_context)
      end

      def merge!(other)
        unless other.class <= Hash
          raise "Must merge! another Hash, given #{other.class.name}"
        end

        other.each do |k, v|
          self[k] = v
        end

        self
      end

      def merge(other)
        self.class.new(self).merge!(other)
      end

      def push_stack
        stack.push({ remove: [], replace: {} })
      end

      def pop_stack
        return unless stack.last

        frame = stack.pop

        frame[:remove].each do |k|
          delete(k)
        end
        frame[:replace].each { |k, v| self[k] = v }
      end

      def clear
        # Copy everything to the replace stack
        merge!(self)

        # Clear the hash
        super
      end

      def [](key)
        super(key.to_sym)
      end

      def []=(key, value)
        key = key.to_sym

        if (frame = stack.last)
          super and return if frame[:replace].key?(key) || frame[:remove].include?(key)

          if key?(key)
            frame[:replace][key] = self[key]
          else
            frame[:remove].push(key)
          end
        end

        super
      end

      private

      def stack
        @stack ||= []
      end
    end
  end
end
