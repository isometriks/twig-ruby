# frozen_string_literal: true

module Twig
  module Rails
    class Config
      def self.defaults
        ActiveSupport::OrderedOptions.new.merge!({
          root: ::Rails.root,
          paths: %w[./ app/views/],
          debug: ::Rails.env.development?,
          allow_helper_methods: true,
          cache: ::Rails.root.join('tmp/cache/twig').to_s,
          charset: 'UTF-8',
          strict_variables: true,
          auto_reload: nil,
          loader: lambda do
            ::Twig::Loader::Filesystem.new(
              current.root,
              current.paths
            )
          end,
        })
      end

      def self.current
        self.configuration ||= defaults
      end

      class_attribute :configuration
    end
  end
end
