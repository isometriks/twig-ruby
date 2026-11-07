# frozen_string_literal: true

module Twig
  module Runtime
    class Context < Hash
      attr_reader :call_context

      def initialize(initial_context = {}, output_buffer: nil, call_context: nil)
        super()

        output_buffer ||= OutputBuffer.new
        @output_buffer_stack = [output_buffer]
        @call_context = call_context
        @popping = false

        merge!(initial_context)
      end

      def original_buffer
        output_buffer_stack.first
      end

      def merge!(other, overwrite: true)
        return self if other == []

        unless other.is_a?(Hash)
          raise "Must merge! another Hash, given #{other.class.name}"
        end

        other.each do |k, v|
          if overwrite || !key?(normalize_key(k))
            self[k] = v
          end
        end

        self
      end

      def keep!(keys)
        (self.keys - keys).each { |k| delete(k) }
      end

      def remove!(*keys)
        keys.each { |k| delete(k) }
      end

      def merge(other, overwrite: true)
        self.class.new(self, call_context:, output_buffer:).merge!(other, overwrite:)
      end

      def only(other)
        self.class.new(other, call_context:, output_buffer:)
      end

      def has?(name)
        if name[0] == '@'
          call_context.instance_variable_defined?(name)
        else
          key?(name) || call_context.respond_to?(name)
        end
      end

      def get(name)
        if name[0] == '@'
          call_context.instance_variable_get(name)
        elsif key?(name)
          self[name]
        elsif call_context.respond_to?(name)
          call_context.send(name)
        end
      end

      def push_stack
        stack.push({ remove: [], replace: {} })
      end

      def pop_stack(new_only = false)
        return unless stack.last

        @popping = true

        frame = stack.pop
        frame[:remove].each do |k|
          delete(k)
        end

        unless new_only
          frame[:replace].each { |k, v| self[k] = v }
        end

        @popping = false
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

      def dup
        self.class.new(to_h, call_context:, output_buffer:)
      end

      def [](key)
        super(normalize_key(key))
      end

      def []=(key, value)
        super if popping

        key = normalize_key(key)

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

      # @return [Context]
      def self.from(context = {}, output_buffer: nil, call_context: nil)
        if context.is_a?(Context)
          context
        else
          new(context, output_buffer:, call_context:)
        end
      end

      # The variables an include or embed passes, which can be any iterable,
      # as PHP's CoreExtension::merge and toArray take: a sequence or any
      # other enumerable gives its keys (integers by position) and values.
      # Anything else raises what merge raises, unless a block gives the error.
      #
      # @return [Hash]
      def self.variables(value)
        return value if value.is_a?(::Hash)
        return EnumerableHash.from(value).to_h if value.is_a?(::Enumerable)

        type = [true, false].include?(value) ? 'bool' : Extension::Core.php_type(value)
        raise yield(type) if block_given?

        raise Error::Runtime, "The \"merge\" filter expects a sequence or a mapping, got \"#{type}\" for argument 2."
      end

      def each(...)
        to_h.each(...)
      end

      private

      attr_reader :popping

      # Names are stored as symbols. The with tag can also add the integer
      # keys of a sequence, which stay integers as they do in PHP.
      def normalize_key(key)
        key.respond_to?(:to_sym) ? key.to_sym : key
      end

      def stack
        @stack ||= []
      end

      def output_buffer_stack
        @output_buffer_stack ||= []
      end
    end
  end
end
