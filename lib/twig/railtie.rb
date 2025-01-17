# frozen_string_literal: true

module Twig
  class RailsRenderer
    def call(template, source)
      <<~TEMPLATE
        ::#{self.class.name}.
          environment.
          load_template("#{template.short_identifier}", call_context: self, output_buffer: @output_buffer).
            render(local_assigns)

        @output_buffer
      TEMPLATE
    end

    def self.loader
      @loader ||= ::Twig::Loader::Filesystem.new(
        Rails.root,
        %w[/ /app/views]
      )
    end

    def self.environment
      options = {
        cache: Rails.root.join('tmp/cache/twig').to_s,
        debug: Rails.env.development?,
      }

      @environment ||= ::Twig::Environment.new(loader, options).tap do |env|
        env.add_extension(::Twig::Extension::Rails.new)
      end
    end
  end

  class Railtie < ::Rails::Railtie
    initializer 'twig_ruby.configure_rails_initialization' do
      ActionView::Template.register_template_handler :twig, RailsRenderer.new
    end
  end
end
