# frozen_string_literal: true

module Twig
  # Anything passed through the Twig OutputBuffer is already
  # being checked for escaping issues, so we can mark everything
  # html_safe here. When being used with Rails, we just pass everything
  # through this buffer into the Rails safe buffer so we don't need a
  # bunch of html_safe calls everywhere.
  class OutputBuffer
    def initialize(decorated = nil)
      @decorated = decorated
      @buffer = +''
    end

    def append=(string)
      self.safe_append = string
    end

    def safe_append=(string)
      if @decorated
        @decorated.safe_append = string
      else
        @buffer << string.to_s.html_safe
      end
    end

    def to_s
      @decorated || @buffer
    end
  end
end
