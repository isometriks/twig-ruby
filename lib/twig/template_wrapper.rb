# frozen_string_literal: true

module Twig
  class TemplateWrapper
    def initialize(environment, template)
      @environment = environment
      @template = template
    end

    def render(context = {}, call_context: nil, output_buffer: nil)
      context = Runtime::Context.from(context, call_context:, output_buffer:)

      template.render(context).to_s
    end

    def render_block(name, context = {}, call_context: nil, output_buffer: nil)
      context = Runtime::Context.from(context, call_context:, output_buffer:)
      context.merge!(environment.globals)

      template.render_block(name, context).to_s
    end

    def block?(name, context = {})
      # Globals are needed to resolve a dynamic parent, e.g. {% extends layout %}
      context = Runtime::Context.from(context).merge(environment.globals, overwrite: false)

      template.block?(name, context)
    end

    # @param [Environment] environment
    def owned_by?(environment)
      self.environment.equal?(environment) && template.owned_by?(environment)
    end

    # A wrapper only works with the environment that loaded it, whose
    # extensions, globals and sandboxing its template was compiled for
    #
    # @param [Environment] environment
    # @return [Template]
    def unwrap(environment)
      unless owned_by?(environment)
        raise Error::Runtime, "A \"#{self.class}\" can only be used with the \"#{Environment}\" that created it."
      end

      template
    end

    private

    # @return [Environment]
    attr_reader :environment

    # @return [Twig::Template]
    attr_accessor :template
  end
end
