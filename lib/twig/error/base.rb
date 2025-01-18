# frozen_string_literal: true

module Twig
  module Error
    class Base < StandardError
      attr_reader :lineno

      # @param [String] message
      # @param [Integer] lineno
      # @param [Source] source
      def initialize(message, lineno = -1, source = nil)
        super(message)

        if source
          name = source.name
          @source_code = source.code
          @source_path = source.path
        else
          name = nil
        end

        @lineno = lineno
        @name = name
        @raw_message = message
      end

      def to_s
        parts = [@raw_message]
        parts << [" in #{@name}"] if @name
        parts << [":#{@lineno}"] if @name && @lineno
        parts << [" on line #{@lineno}"] if !@name && @lineno

        parts.join
      end
    end
  end
end
