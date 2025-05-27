# frozen_string_literal: true

module Twig
  module Util
    class CallableArgumentsExtractor
      # @param [Node::Expression::Call] node
      # @param [Callable] twig_callable
      # @param [Environment] environment
      def initialize(node, twig_callable, environment)
        @node = node
        @twig_callable = twig_callable
        @environment = environment
      end

      # @param [Node::Nodes] arguments
      def extract_arguments(arguments)
        # Check argument order first
        found_named = false
        arguments.nodes.each_key do |key|
          if key.is_a?(Integer)
            if found_named
              raise Error::Syntax.new(
                "Positional arguments cannot be used after named arguments for #{@twig_callable.type} " \
                "\"#{@twig_callable.name}\".",
                @node.lineno,
                @node.source_context
              )
            end
          else
            found_named = true
          end
        end

        called_arguments = destination_arguments.keys.to_h { |k| [k, false] }

        spreads, arguments = arguments.nodes.partition do |_, node|
          node.is_a?(Node::Expression::Unary::Spread)
        end.map(&:to_h)

        positional, kwargs = arguments.partition do |key, _node|
          key.is_a?(Integer)
        end.map(&:to_h)

        positional = positional.values
        positional_count = positional.length

        kwargs.transform_keys!(&:to_sym)
        resolved_positional = []
        resolved_kwargs = {}
        rest = false
        keyrest = false

        destination_arguments.each do |name, type|
          if positional.any?
            case type
            when :req, :opt
              resolved_positional << positional.shift
            when :keyreq, :key
              arg = positional.shift

              if arg.is_a?(Node::Expression::Unary::HashSpread)
                keyrest = true
                resolved_positional << arg
              else
                resolved_kwargs[name] = arg
              end
            when :rest
              resolved_positional += positional
              positional = []
              rest = true
              next
            when :keyrest
              arg = positional.shift

              if arg.is_a?(Node::Expression::Unary::HashSpread)
                keyrest = true
                resolved_positional << arg
              else
                raise Error::Syntax.new(
                  "Expected a hash spread for argument \"#{name}\" " \
                  "for #{@twig_callable.type} \"#{@twig_callable.name}\".",
                  @node.lineno,
                  @node.source_context
                )
              end

              next
            else
              raise "Unknown argument type: #{name} #{type}"
            end
          elsif kwargs.key?(name)
            resolved_kwargs[name] = kwargs.delete(name)
          else
            case type
            when :opt, :key, :rest
              next
            when :keyrest
              keyrest = true
              resolved_kwargs.merge!(kwargs)
              kwargs = {}
              next
            else
              # If we have spreads, we just can't know until runtime since we don't know if it's a
              # positional spread or kwarg spread because both use ...
              unless spreads.any? || keyrest
                raise Error::Syntax.new(
                  "Value for argument \"#{name}\" is required for #{@twig_callable.type} \"#{@twig_callable.name}\".",
                  @node.lineno,
                  @node.source_context
                )
              end
            end
          end

          called_arguments[name] = true
        end

        # If any of our remaining kwargs intersect with called_arguments then we have a duplicate key
        duplicated = called_arguments.select { |_k, v| v }.keys & kwargs.keys
        duplicated = duplicated.map(&:to_s)
        duplicated = duplicated[0] if duplicated.one?

        unless duplicated.empty?
          raise Error::Syntax.new(
            "Argument #{duplicated.inspect} is defined twice for #{@twig_callable.type} " \
            "\"#{@twig_callable.name}\".",
            @node.lineno,
            @node.source_context
          )
        end

        unexpected_arguments = []
        unknown_argument = nil

        # If there's no keyrest and any kwargs left, they are extraneous
        if !keyrest && kwargs.any?
          unexpected_arguments += kwargs.keys
          unknown_argument = kwargs.values.first
        end

        # If there's a rest and any positional left, they are extraneous
        if !rest && positional.any?
          unexpected_arguments += [
            *((positional_count - positional.length)...positional_count),
          ]
          unknown_argument = positional.first
        end

        if unexpected_arguments.any?
          unknown_argument ||= @node

          raise Error::Syntax.new(
            "Unknown argument \"#{unexpected_arguments.join(', ')}\" " \
            "for #{@twig_callable.type} \"#{@twig_callable.name}(#{destination_arguments.keys.join(', ')})\".",
            unknown_argument.lineno,
            unknown_argument.source_context
          )
        end

        [resolved_positional + spreads.values, resolved_kwargs]
      end

      private

      # @return [Callable]
      attr_reader :twig_callable

      # @return [Environment]
      attr_reader :environment

      def destination_arguments
        arguments = callable_method.parameters.to_h { |k, v| [v, k] }

        if @node.nodes.key?(:node)
          arguments.shift
        end

        if twig_callable.needs_charset?
          arguments.shift
        end

        if twig_callable.needs_environment?
          arguments.shift
        end

        if twig_callable.needs_context?
          arguments.shift
        end

        twig_callable.arguments.each do
          arguments.shift
        end

        arguments
      end

      # @return [Method]
      def callable_method
        callable = twig_callable.callable

        case callable
        when ::Array
          if callable[0] == :runtime
            _, klass, method = callable

            environment.runtime(klass).method(method.to_sym)
          else
            extension, method = callable[0, 2]
            extension = extension.class.name if extension.is_a?(Extension::Base)

            environment.extension(extension.delete_prefix('::')).method(method.to_sym)
          end
        when ::Method, ::Proc
          callable
        else
          raise "Callable not supported: #{callable.inspect}"
        end
      end
    end
  end
end
