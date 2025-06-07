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
    end

    def call(context = {}, blocks = {})
      raise 'call is not implemented'
    end

    # @param [Runtime::Context] context
    def render(context)
      unless context.is_a?(Runtime::Context)
        raise Error::Runtime, 'Render must implement Twig::Runtime::Context'
      end

      call(context)
    rescue Error::Base => e
      e.source_context = source_context unless e.source_context
      raise e
    end

    def render_block(name, context, blocks = {}, use_blocks: true, template_context: self)
      unless context.is_a?(Runtime::Context)
        context = Runtime::Context.new(context)
      end

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
          context.buffer_and_return do
            template[0].public_send(template[1], context, blocks)
          end.to_s.html_safe
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
        parent.render_block(name, context, self.blocks.merge(blocks), use_blocks: false, template_context:)
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
      if blocks.key?(name) && blocks[name][0].is_a?(Template)
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
      if @traits.key?(name.to_sym)
        @traits[name.to_sym][0].render_block(@trait_aliases[name.to_sym] || name, context, blocks, use_blocks: false)
      elsif (parent = get_parent(context))
        parent.render_block(name, context, blocks, use_blocks: false)
      else
        raise Error::Runtime.new(
          "The template has no parent and no traits defining the #{name} block.",
          -1,
          source_context
        )
      end
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
        @parents[parent] = load(parent, -1)
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

      macro_method.call(context.call_context, **mapped_arguments)
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
        "Macro \"#{name.delete_prefix('macro_')}\" is not defined in #{template_name}.",
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

    def unwrap
      self
    end

    private

    # @param [String, TemplateWrapper] template
    # @return [Template]
    def load(template, line, index = nil)
      if template.is_a?(TemplateWrapper)
        return template.unwrap
      end

      env.load_template(template, index:)
    rescue Error::Base => e
      unless e.source_context
        e.source_context = source_context
      end

      # @todo guess template line if possible

      raise e
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
