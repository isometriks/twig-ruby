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

      # Get file extension
      extension = File.extname(name)[1..]

      case extension
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
  end
end
