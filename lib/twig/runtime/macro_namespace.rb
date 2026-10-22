# frozen_string_literal: true

module Twig
  module Runtime
    # The macros a template declares, as seen through `import` or `_self`. A macro that
    # isn't declared by the template itself is looked up in its parents.
    class MacroNamespace
      # @param [Template] template
      # @param [Hash{String => Macro}] macros
      def initialize(template, macros)
        @template = template
        @macros = macros
      end

      # @param [String] name
      # @param [Context] context
      def has?(name, context)
        !resolve(name, context).nil?
      end

      # @param [String] name
      # @param [Hash{Integer, String => Object}] arguments
      # @param [Context] context
      # @param [Integer] lineno
      # @param [Source] source
      def call(name, arguments, context, lineno, source)
        unless (macro = resolve(name, context))
          raise Error::Runtime.new(
            "Macro \"#{name}\" is not defined in template \"#{@template.template_name}\".",
            lineno,
            source
          )
        end

        macro.call(arguments, context.call_context, source, lineno)
      end

      protected

      # @return [Macro, nil]
      def declared(name)
        @macros[name]
      end

      # @return [MacroNamespace, nil]
      def parent(context)
        return unless (parent = @template.get_parent(context))

        parent.unwrap.macro_namespace
      end

      private

      # @return [Macro, nil]
      def resolve(name, context)
        namespace = self

        while namespace
          if (macro = namespace.declared(name))
            return macro
          end

          namespace = namespace.parent(context)
        end

        nil
      end
    end
  end
end
