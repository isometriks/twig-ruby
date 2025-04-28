# frozen_string_literal: true

module Twig
  # Base class for compiled templates
  class Template
    ARRAY_CALL = :array_call
    METHOD_CALL = :method_call
    ANY_CALL = :any_call

    attr_accessor :blocks

    # @param [Environment] environment
    def initialize(environment, call_context: nil, output_buffer: nil)
      @environment = environment
      @parent = nil
      @parents = {}
      @blocks = {}
      @traits = {}
      @macros = {}
      @trait_aliases = {}
      @call_context = call_context
      @output_buffer = output_buffer || OutputBuffer.new
    end

    def call(context = {}, blocks = {})
      raise 'call is not implemented'
    end

    def render(context = {})
      call(Runtime::Context.new(context))
    rescue Error::Base => e
      e.source_context = source_context unless e.source_context
      raise e
    end

    def yield_block(name, context = {}, blocks = {}, use_blocks: true, template_context: self)
      name = name.to_sym

      template = if use_blocks && blocks.key?(name)
                   blocks[name]
                 elsif self.blocks.key?(name)
                   self.blocks[name]
                 end

      # avoid RCEs when sandbox is enabled
      if !template.nil? && !template[0].is_a?(::Twig::Template)
        raise Error::Logic, 'A block must be a method on a ::Twig::Template instance.'
      end

      if !template.nil?
        begin
          template[0].public_send(template[1], context, blocks)
        rescue Error::Base => e
          unless e.source_context
            e.source_context = template[0].source_context
          end

          # @todo Guess template line
          raise e
        rescue StandardError => e
          # Rails wraps exceptions that happened using render
          if e.respond_to?(:cause) && e.cause.is_a?(Error::Base)
            e = e.cause
            unless e.source_context
              e.source_context = template[0].source_context
            end

            raise e
          end

          raise Error::Runtime.new(
            "An exception has been thrown during the rendering of a template (#{e})",
            -1,
            template[0].source_context
          )
        end
      elsif (parent = get_parent(context))
        parent.yield_block(name, context, self.blocks.merge(blocks), use_blocks: false, template_context:)
      elsif blocks.key?(name)
        raise Error::Runtime.new(
          "Block '#{name}' should not call parent() in #{blocks[name].template_name}",
          -1,
          blocks[name].source_context
        )
      else
        raise Error::Runtime.new(
          "Block '#{name}' on template '#{template_name}' does not exist.",
          -1,
          template_context.source_context
        )
      end
    end

    def block?(name, context, blocks = {})
      name = name.to_sym
      if blocks.key?(name) && blocks[name][0].is_a?(self.class)
        return true
      end

      if @blocks&.key?(name)
        return true
      end

      if (parent = get_parent(context))
        return parent.block?(name, context)
      end

      false
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

    # @return [Template, false]
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

    def macro?(name, context)
      if respond_to?(name.to_sym)
        return true
      end

      unless (parent = get_parent(context))
        return false
      end

      parent.macro?(name, context)
    end

    def render_macro(name, context, args, lineno, source)
      macro_method = macro_template_reference(name, context, lineno, source)
      macro_arguments = macro_method.parameters.select { |arg| arg[0] == :key }.map { |_, arg| arg }
      mapped_arguments = {}
      kwarg = false

      args.each do |key, value|
        if !kwarg && key.is_a?(Integer)
          mapped_key = macro_arguments[key]
        elsif kwarg && key.is_a?(Integer)
          raise Error::Runtime.new('Cannot place a positional argument after a keyword argument', lineno, source)
        else
          kwarg = true
          mapped_key = key.to_sym
        end

        if mapped_arguments.key?(mapped_key)
          raise Error::Runtime.new("Argument \"#{mapped_key}\" passed twice", lineno, source)
        end

        mapped_arguments[mapped_key] = value
      end

      macro_method.call(**mapped_arguments)
    end

    # @return [Method]
    def macro_template_reference(name, context, lineno, source)
      if respond_to?(name.to_sym)
        return method(name.to_sym)
      end

      parent = self
      while (parent = parent.get_parent(context))
        if parent.respond_to?(name.to_sym)
          return parent.method(name.to_sym)
        end
      end

      raise Error::Runtime.new(
        "Macro \"#{name.delete_prefix('macro_')}\" is not defined in #{template_name}",
        lineno,
        source
      )
    end

    def source_context
      raise NotImplementedError
    end

    def traitable?
      true
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

    # @return [Environment]
    def env
      @environment
    end
  end
end
