# frozen_string_literal: true

module Twig
  class Source
    attr_reader :code, :name, :path

    def initialize(code, name, path = '')
      @code = code
      @name = name
      @path = path
    end

    # Returns the 1-based column of a 0-based offset in the code, or nil when
    # the offset is unknown (nil or negative).
    #
    # The column counts bytes, as Twig does, while the offset counts
    # characters, as the lexer's cursor does.
    #
    # @param [Integer, nil] offset
    # @return [Integer, nil]
    def column(offset)
      return nil if offset.nil? || offset.negative?

      before = code[0, offset].gsub(/\r\n?/, "\n")
      line_start = before.rindex("\n")

      (line_start ? before[(line_start + 1)..] : before).bytesize + 1
    end
  end
end
