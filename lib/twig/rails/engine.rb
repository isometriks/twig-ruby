# frozen_string_literal: true

require 'rails'
require 'English'
require 'twig/rails/config'
require 'twig/rails/renderer'
require 'twig/rails/form/twig'
require 'twig/rails/form/bootstrap'

module Twig
  # @return [Environment]
  def self.environment
    @@environment ||= begin
      options = ::Twig::Rails::Config.current.slice(
        :autoescape,
        :cache,
        :debug,
        :allow_helper_methods,
        :charset,
        :strict_variables,
        :auto_reload
      )

      ::Twig::Environment.new(loader, options).tap do |env|
        env.add_extension(::Twig::Extension::Rails.new)
        env.add_extension(::Twig::Extension::Debug.new) if env.debug?
      end
    end
  end

  def self.loader
    @@loader ||= ::Twig::Rails::Config.current.loader.call
  end

  module Rails
    class Engine < ::Rails::Engine
      config.before_configuration do |app|
        app.config.twig = Config.current
      end

      initializer 'twig_ruby.configure_rails_initialization' do
        ActionView::Template.register_template_handler :twig, Renderer.new
      end
    end
  end
end
