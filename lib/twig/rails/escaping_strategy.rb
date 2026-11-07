# frozen_string_literal: true

module Twig
  module Rails
    # Picks the autoescaping strategy from a Rails template name, which looks
    # like name.locale.format+variant.twig. Rails calls the plain text format
    # "text" rather than "txt", so a mailer's text part (welcome.text.twig) is
    # left unescaped here. Everything else goes to the core guess, which stays
    # the same as Twig PHP's.
    class EscapingStrategy
      # Matches a "+variant" suffix on the format, before an optional .twig.
      VARIANT = %r{\+[^./\\]*(?=(?:\.twig)?\z)}

      # @param [String] name The template name
      # @return [Symbol, false] The escaping strategy name to use or false to disable
      def self.guess(name)
        name = name.sub(VARIANT, '')

        return false if ::Twig::FileExtensionEscapingStrategy.extension(name.delete_suffix('.twig')) == 'text'

        ::Twig::FileExtensionEscapingStrategy.guess(name)
      end
    end
  end
end
