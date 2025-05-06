# frozen_string_literal: true

require 'English'

module Twig
  class RailsRenderer
    def call(template, source)
      <<~TEMPLATE
        ::#{self.class.name}.
          environment.
          load_template(
            "#{template.short_identifier}",
            call_context: self,
            output_buffer: Twig::OutputBuffer.new(@output_buffer),
          ).
          render(local_assigns)

        @output_buffer
      TEMPLATE
    end

    def translate_location(spot, _backtrace_location, source)
      exception = $ERROR_INFO

      return nil unless exception.is_a?(::ActionView::Template::Error)

      twig_exception = exception.cause

      return nil unless twig_exception.is_a?(::Twig::Error::Base)

      spot[:script_lines] = twig_exception.source_context&.code&.lines || source.lines
      spot[:first_lineno] = spot[:last_lineno] = twig_exception.lineno
      spot[:first_column] = spot[:last_column] = 0

      spot
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
        allow_helper_methods: true,
      }

      @environment ||= ::Twig::Environment.new(loader, options).tap do |env|
        env.add_extension(::Twig::Extension::Rails.new)
        env.add_extension(::Twig::Extension::Debug.new)
      end
    end
  end

  class Railtie < ::Rails::Railtie
    initializer 'twig_ruby.configure_rails_initialization' do
      ActionView::Template.register_template_handler :twig, RailsRenderer.new
    end
  end
end
