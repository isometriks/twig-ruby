# frozen_string_literal: true

module Twig
  module Error
    class Base < StandardError
      # @return [Integer]
      attr_reader :lineno

      # @param [String] message
      # @param [Integer] lineno
      # @param [Source] source
      def initialize(message, lineno = -1, source = nil, previous = nil)
        super('')

        @lineno = lineno
        @source = source
        @raw_message = message
        @previous = previous

        update_repr
      end

      # @return [Source, nil]
      def source_context
        @source
      end

      # @param [Source, nil] source
      def source_context=(source)
        @source = source
        update_repr
      end

      def to_s
        @message
      end

      def lineno=(lineno)
        @lineno = lineno
        update_repr
      end

      def append_message(raw_message)
        @raw_message += raw_message
        update_repr
      end

      def guess
        locations = [self, @previous].compact.map(&:backtrace_locations).flatten
        locations.each do |location|
          next unless location.label&.start_with?('Twig::Compiled::')

          klass, _method = location.label.split('#')
          klass = Twig::Compiled.const_get(klass)

          next unless source.name == klass.source_context.name

          klass.debug_info.each do |source_line, template_line|
            next unless source_line <= location.lineno

            self.lineno = template_line
            update_repr
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end
        end
      end

      private

      # @return [Source, nil]
      attr_reader :source

      def update_repr
        if !source.nil? && source.path
          # only update file and line together
          @file = source.path
          @line = lineno.positive? ? lineno : -1
        end

        @message = @raw_message.dup
        last = @message[-1]

        if (punctuation = %w[. ?].include?(last) ? last : '')
          @message = @message[0...-1]
        end

        if !source.nil? && source.name
          @message += " in \"#{source.name}\""
        end

        if lineno.positive?
          @message += " at line #{lineno}"
        end

        unless punctuation.empty?
          @message += punctuation
        end
      end
    end
  end
end
