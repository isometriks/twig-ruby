module Twig
  class RailsRenderer
    def call(template, source)
      name = template.short_identifier
      environment = self.class.environment
      class_name = environment.template_class(name)

      <<~TEMPLATE
        #{environment.render_ruby(template.short_identifier)}
        #{class_name}.new(#{self.class.name}.environment).render(local_assigns)
      TEMPLATE
    end

    def self.loader
      @loader ||= ::Twig::Loader::File.new([Rails.root.to_s + "/"])
    end

    def self.environment
      @environment ||= ::Twig::Environment.new(self.loader)
    end
  end

  class Railtie < ::Rails::Railtie
    initializer 'twig_ruby.configure_rails_initialization' do
      ActionView::Template.register_template_handler :twig, RailsRenderer.new
    end
  end
end
