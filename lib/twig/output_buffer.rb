# frozen_string_literal: true

module Twig
  class OutputBuffer
    def initialize
      @buffer = +''
    end

    def append=(string)
      unless string.nil?
        string = string.to_s

        if string.html_safe?
          @buffer << string
        else
          @buffer << CGI.escapeHTML(string)
        end
      end
    end

    def safe_append=(string)
      @buffer << string.html_safe
    end

    def to_s
      @buffer
    end
  end
end
