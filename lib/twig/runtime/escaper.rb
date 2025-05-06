# frozen_string_literal: true

module Twig
  module Runtime
    class Escaper
      def initialize(charset)
        @charset = charset
      end

      def escape(string, strategy = :html, charset = nil, autoescape = false)
        # Allow strings marked as html_safe to get through without escaping
        if string.html_safe? && %i[html html_attr].include?(strategy)
          return string
        end

        CGI.escapeHTML(string.to_s)
      end
    end
  end
end
