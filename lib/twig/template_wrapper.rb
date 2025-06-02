# frozen_string_literal: true

module Twig
  class TemplateWrapper
    def initialize(environment, template)
      @environment = environment
      @template = template
    end

    def render(context = {}, call_context: nil, output_buffer: OutputBuffer.new)
      unless context.is_a?(Runtime::Context)
        context = Runtime::Context.new(context, call_context:, output_buffer:)
      end

      template.render(context).to_s
    end

    def render_block(name, context = {}, call_context: nil, output_buffer: OutputBuffer.new)
      unless context.is_a?(Runtime::Context)
        context = Runtime::Context.new(context, call_context:, output_buffer:)
      end

      context.merge!(environment.globals)

      template.render_block(name, context).to_s
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
