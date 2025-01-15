# frozen_string_literal: true

module Twig
  class RailsRenderer
    def call(template, source)
      name = template.short_identifier
      environment = self.class.environment
      class_name = environment.template_class(name)

      <<~TEMPLATE
        #{environment.render_ruby(template.short_identifier)}
        #{class_name}.new(
          #{self.class.name}.environment,#{' '}
          call_context: self,
          output_buffer: @output_buffer
        ).render(local_assigns)
        @output_buffer
      TEMPLATE
    end

    def self.loader
      @loader ||= ::Twig::Loader::File.new([
        "#{Rails.root.to_s}/",
        "#{Rails.root.to_s}/app/views/",
      ])
    end

    def self.environment
      @environment ||= ::Twig::Environment.new(self.loader).tap do |env|
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
