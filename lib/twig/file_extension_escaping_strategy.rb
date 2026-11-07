# frozen_string_literal: true

module Twig
  class FileExtensionEscapingStrategy
    # Guesses the best autoescaping strategy based on the file name.
    #
    # @param [String] name The template name
    # @return [Symbol, false] The escaping strategy name to use or false to disable
    def self.guess(name)
      # Return html for directories
      if name.end_with?('/') || name.end_with?('\\')
        return :html
      end

      # Remove .twig extension if present
      if name.end_with?('.twig')
        name = name[0...-5]
      end

      case extension(name)
      when 'js', 'json'
        :js
      when 'css'
        :css
      when 'txt'
        false
      else
        :html
      end
    end

    # The extension of a file name, as PHP's pathinfo gives it: what follows
    # the last dot of the base name, even when the name starts with it, so
    # ".js" has the extension "js", where File.extname gives none.
    #
    # @param [String] name
    # @return [String]
    def self.extension(name)
      base = name.rpartition('/').last

      base.include?('.') ? base.rpartition('.').last : ''
    end
  end
end
