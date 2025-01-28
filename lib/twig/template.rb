# frozen_string_literal: true

module Twig
  # Base class for compiled templates
  class Template
    ARRAY_CALL = :array_call
    METHOD_CALL = :method_call
    ANY_CALL = :any_call

    # @param [Environment] environment
    def initialize(environment, call_context: nil, output_buffer: nil)
      @environment = environment
      @parent = nil
      @parents = {}
      @traits = {}
      @blocks = {}
      @call_context = call_context
      @output_buffer = output_buffer || OutputBuffer.new
    end

    def call(context = {}, blocks = {})
      raise 'call is not implemented'
    end

    def render(context = {})
      call(Context.new(context))
    end

    def yield_block(name, context = {}, blocks = {}, use_blocks: true)
      object = self

      if blocks.key?(name)
        object = blocks[name]
      end

      object.public_send(:"block_#{name}", context, blocks)
    end

    def render_parent_block(name, context, blocks = {})
      if @traits.key?(name)
        # @todo traits
        raise NotImplementedError
      elsif (parent = get_parent(context))
        parent.yield_block(name, context, blocks, use_blocks: false)
      else
        raise Error::Runtime.new(
          "The template has no parent and no traits defining the #{name} block.",
          -1,
          source_context
        )
      end

      # Return an empty string since the return would get appended twice
      ''
    end

    def source_context
      raise NotImplementedError
    end

    private

    # @param [String] name
    # @return ]Template]
    def load_template(name, template_name = '', template_line = nil)
      env.load_template(name, call_context: @call_context, output_buffer: @output_buffer)
    end

    # Overloaded by children
    def do_get_parent(context)
      false
    end

    def get_parent(context)
      if @parent
        return @parent
      end

      unless (parent = do_get_parent(context))
        return false
      end

      if parent.is_a?(self.class)
        return @parents[parent.source_context.name] = parent
      end

      unless @parents.key?(parent)
        @parents[parent] = load_template(parent)
      end

      @parents[parent]
    end

    # @return [Environment]
    def env
      @environment
    end
  end
end
