module Twig
  module Error
    class Base < StandardError
      # @param [String] message
      # @param [Integer] lineno
      # @param [Source] source
      def initialize(message, lineno = -1, source = nil)
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
        parts << ["in #{@name}"] if @name
        parts << ["on line #{@lineno}"] if @lineno

        parts.join(" ")
      end
    end
  end
end
