# frozen_string_literal: true

module Twig
  # Base class for compiled templates
  class Template
    ARRAY_CALL = :array_call
    METHOD_CALL = :method_call
    ANY_CALL = :any_call

    attr_accessor :blocks

    # @param [Environment] environment
    def initialize(environment)
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
        raise Error::Runtime, 'Render must implement Twig::Runtime::Context.'
      end

      render_with_blocks(context.merge(env.globals), blocks.merge(blocks))
    end

    def render_with_blocks(context = {}, blocks = {})
      call(context, blocks)
    rescue Error::Base => e
      e.source_context = source_context unless e.source_context
      e.guess if e.lineno == -1
      raise e
    rescue StandardError => e
      exception = Error::Runtime.new(
        "An exception has been thrown during the rendering of a template (\"#{e}\").",
        -1,
        source_context,
        e
      )
      exception.guess

      raise exception
    end

    def render_block(name, context, blocks = {}, use_blocks: true, template_context: self)
      unless context.is_a?(Runtime::Context)
        context = Runtime::Context.new(context)
      end

      name = name.to_sym
      template = if use_blocks && blocks.key?(name)
                   blocks[name]
                 elsif self.blocks.key?(name)
                   # expose this template's own blocks so nested block() calls resolve
                   # against them when the block is rendered directly (e.g. block(name, template))
                   blocks = self.blocks.merge(blocks)
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

          if e.lineno == -1
            e.guess
          end

          raise e
        rescue StandardError => e
          # Rails wraps exceptions that happened using render
          if e.respond_to?(:cause) && e.cause.is_a?(Error::Base)
            e = e.cause
            unless e.source_context
              e.source_context = template[0].source_context
            end
          end

          exception = Error::Runtime.new(
            "An exception has been thrown during the rendering of a template (#{e})",
            -1,
            template[0].source_context,
            e
          )
          exception.guess

          raise exception
        end
      elsif (parent = get_parent(context))
        parent.render_block(name, context, self.blocks.merge(blocks), use_blocks: false, template_context:)
      elsif blocks.key?(name)
        raise Error::Runtime.new(
          "Block \"#{name}\" should not call parent() in \"#{blocks[name][0].template_name}\" " \
          "as the block does not exist in the parent template \"#{template_name}\".",
          -1,
          blocks[name][0].source_context
        )
      else
        raise Error::Runtime.new(
          "Block \"#{name}\" on template \"#{template_name}\" does not exist.",
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

      if parent.is_a?(Template)
        return @parents[parent.source_context.name] = parent
      end

      unless @parents.key?(parent)
        @parents[parent] = load(parent, -1)
      end

      @parents[parent]
    end

    # The macros this template declares, as imported by `import` or reached through `_self`
    #
    # @return [Runtime::MacroNamespace]
    def macro_namespace
      @macro_namespace ||= Runtime::MacroNamespace.new(self, load_declared_macros)
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
      if template.is_a?(Array)
        return env.resolve_template(template).unwrap
      end

      if template.is_a?(TemplateWrapper)
        return template.unwrap
      end

      if template == template_name
        klass = self.class.name

        if (pos = klass.rindex('___'))
          klass = klass[0...pos]
        end
      else
        klass = env.template_class(template)
      end

      env.load_template(klass, template, index:)
    rescue Error::Base => e
      unless e.source_context
        e.source_context = source_context
      end

      if e.lineno.positive?
        raise e
      end

      if line == -1
        e.guess
      else
        e.lineno = line
      end

      raise e
    end

    # Overloaded by children
    def do_get_parent(context)
      false
    end

    # Overloaded by children that declare macros
    #
    # @return [Hash{String => Runtime::Macro}]
    def load_declared_macros
      {}
    end

    # @return [Environment]
    def env
      @environment
    end
  end
end
