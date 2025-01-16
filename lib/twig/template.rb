# frozen_string_literal: true

module Twig
  # Base class for compiled templates
  class Template
    # @param [Environment] environment
    def initialize(environment, call_context: nil, output_buffer: nil)
      @environment = environment
      @parents = {}
      @blocks = {}
      @call_context = call_context
      @output_buffer = output_buffer || OutputBuffer.new
    end

    def call(context = {}, blocks = {})
      raise 'call is not implemented'
    end

    def render(context = {}, blocks = {})
      call(context.transform_keys(&:to_sym), blocks)
    end

    def yield_block(name, context = {}, blocks = {})
      object = self

      if blocks.key?(name)
        object = blocks[name]
      end

      object.public_send(:"block_#{name}", context, blocks)
    end

    private

    # @param [String] name
    # @return ]Template]
    def load_template(name, template_name = '', template_line = nil)
      env.load_template(name, call_context: @call_context, output_buffer: @output_buffer)
    end

    # @return [Environment]
    def env
      @environment
    end
  end
end
