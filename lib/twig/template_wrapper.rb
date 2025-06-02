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
      context = Runtime::Context.from(context)

      template.block?(name, context)
    end

    # @return [Template]
    def unwrap
      template
    end

    private

    # @return [Environment]
    attr_reader :environment

    # @return [Twig::Template]
    attr_accessor :template
  end
end
