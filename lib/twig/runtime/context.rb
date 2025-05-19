# frozen_string_literal: true

module Twig
  module Runtime
    class Context < Hash
      attr_reader :call_context

      def initialize(initial_context = {}, output_buffer: OutputBuffer.new, call_context: nil)
        super()

        @output_buffer_stack = [output_buffer]
        @call_context = call_context

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
        self.class.new(self, call_context:, output_buffer:).merge!(other)
      end

      def only(other)
        self.class.new(other, call_context:, output_buffer:)
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

      def output_buffer
        output_buffer_stack.last
      end

      def push_output_buffer
        output_buffer_stack.push(OutputBuffer.new)
      end

      def pop_output_buffer
        output_buffer_stack.pop
      end

      def buffer_and_return(&)
        push_output_buffer
        yield
        pop_output_buffer
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

      def output_buffer_stack
        @output_buffer_stack ||= []
      end
    end
  end
end
