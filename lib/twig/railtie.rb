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

    def translate_location(spot, backtrace_location, source)
      template = backtrace_location.path.delete_prefix(Rails.root.to_s)

      # Attempt to recompile the template to find where the syntax error is
      # otherwise just do what would have happened anyway
      begin
        self.class.environment.render_ruby(template)
      rescue ::Twig::Error::Syntax => e
        return spot.merge({
          first_lineno: e.lineno,
          last_lineno: e.lineno + 1,
          script_lines: source.lines,
        })
      rescue StandardError
        # Nothing, don't add another exception to the problem
      end

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
      end
    end
  end

  class Railtie < ::Rails::Railtie
    initializer 'twig_ruby.configure_rails_initialization' do
      ActionView::Template.register_template_handler :twig, RailsRenderer.new
    end
  end
end
