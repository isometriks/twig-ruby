# frozen_string_literal: true

module Twig
  module Extension
    class Rails < Extension::Base
      def filters
        [
          TwigFilter.new('striptags', method(:strip_tags)),
        ]
      end

      def token_parsers
        [
          TokenParser::Cache.new,
        ]
      end

      def strip_tags(string, tags = [])
        ApplicationController.helpers.sanitize(string, tags:)
      end
    end
  end
end
