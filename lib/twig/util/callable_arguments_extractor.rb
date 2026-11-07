# frozen_string_literal: true

module Twig
  module Util
    # Binds the arguments of a call to the parameters of a Twig callable at
    # compile time, as Twig's CallableArgumentsExtractor does.
    class CallableArgumentsExtractor
      # @param [Node::Expression::Call] node
      # @param [Callable] twig_callable
      # @param [Environment] environment
      def initialize(node, twig_callable, environment)
        @node = node
        @twig_callable = twig_callable
        @environment = environment
      end

      # Follows the loop of Twig's extractor: each parameter takes the
      # argument named after it, compared as Twig compares names (lowercase,
      # without underscores, so some_value: and someValue: are the same), or
      # else the next positional argument. A positional argument for a keyword
      # parameter is passed as that keyword, which is how the core filters
      # with keyword parameters take positional arguments. Spreads are
      # unpacked at runtime, by Runtime::ArgumentSpreader, so they go last and
      # a required argument isn't checked when there is one.
      #
      # @param [Node::Nodes] arguments
      # @return [Array(Array<Node::Base>, Hash{Symbol => Node::Base})] the
      #   positional arguments, with the spreads last, and the keyword arguments
      def extract_arguments(arguments)
        extracted = {}
        names = {}
        spreads = []
        named = false

        arguments.nodes.each do |name, node|
          if name.is_a?(Integer)
            if named
              raise syntax_error(
                "Positional arguments cannot be used after named arguments for #{callable_type} \"#{callable_name}\"."
              )
            end

            if node.is_a?(Node::Expression::Unary::Spread)
              spreads << node
            else
              extracted[name] = node
            end
          else
            named = true
            normalized = normalize(name)
            extracted[normalized] = node
            names[normalized] = name
          end
        end

        positional = []
        kwargs = {}
        parameter_names = []
        missing = []
        position = 0

        parameters.each do |type, parameter|
          next if type == :block

          twig_name = twig_callable.argument_name(parameter)
          parameter_names << twig_name unless %i[* **].include?(parameter)

          case type
          when :rest
            while extracted.key?(position)
              positional << extracted.delete(position)
              position += 1
            end
          when :keyrest
            if extracted.key?(position)
              raise syntax_error(
                "Expected a hash spread for argument \"#{twig_name}\" for #{callable_type} \"#{callable_name}\"."
              )
            end

            extracted.each_key.reject { |key| key.is_a?(Integer) }.each do |key|
              kwargs[names[key].to_sym] = extracted.delete(key)
            end
          else
            key = [normalize(twig_name), normalize(parameter)].find { |name| extracted.key?(name) }

            if key
              if extracted.key?(position)
                raise syntax_error(
                  "Argument \"#{twig_name}\" is defined twice for #{callable_type} \"#{callable_name}\"."
                )
              end

              if %i[req opt].include?(type)
                raise unknown_default_error(twig_name, parameter_names, missing) if missing.any?

                positional << extracted.delete(key)
              else
                kwargs[parameter] = extracted.delete(key)
              end
            elsif extracted.key?(position)
              argument = extracted.delete(position)
              position += 1

              if %i[req opt].include?(type)
                positional << argument
              else
                kwargs[parameter] = argument
              end
            elsif type == :opt
              # Ruby can't tell its default, so nothing named after it can be passed by position
              missing << twig_name
            elsif %i[req keyreq].include?(type) && spreads.empty?
              raise syntax_error(
                "Value for argument \"#{snake_case(twig_name)}\" is required for #{callable_type} \"#{callable_name}\"."
              )
            end
          end
        end

        unless extracted.empty?
          unknown = extracted.values.first

          raise Error::Syntax.new(
            "Unknown argument#{'s' if extracted.length > 1} \"#{extracted.keys.join('", "')}\" " \
            "for #{callable_type} \"#{callable_name}(#{parameter_names.join(', ')})\".",
            unknown.lineno,
            unknown.source_context
          )
        end

        [positional + spreads, kwargs]
      end

      private

      # @return [Callable]
      attr_reader :twig_callable

      # @return [Environment]
      attr_reader :environment

      def callable_type
        twig_callable.type
      end

      def callable_name
        twig_callable.name
      end

      # As Twig compares argument names
      def normalize(name)
        name.to_s.downcase.delete('_')
      end

      def snake_case(name)
        name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z0-9])([A-Z])/, '\1_\2').downcase
      end

      def syntax_error(message)
        Error::Syntax.new(message, @node.lineno, @node.source_context)
      end

      # Twig raises this for an internal PHP function, which can't tell the
      # default of an optional argument either
      def unknown_default_error(name, parameter_names, missing)
        syntax_error(
          "Argument \"#{name}\" could not be assigned for #{callable_type} " \
          "\"#{callable_name}(#{parameter_names.join(', ')})\" because it is mapped to a Ruby callable which " \
          "cannot determine default value for optional argument#{'s' unless missing.one?} " \
          "\"#{missing.join('", "')}\" (use #{missing.one? ? 'a keyword parameter' : 'keyword parameters'} instead)."
        )
      end

      # @return [Array<Array(Symbol, Symbol)>] the type and name of each
      #   parameter of the Ruby callable that templates pass
      def parameters
        parameters = callable_method.parameters

        skip = twig_callable.arguments.length
        skip += 1 if @node.nodes.key?(:node)
        skip += 1 if twig_callable.needs_charset?
        skip += 1 if twig_callable.needs_environment?
        skip += 1 if twig_callable.needs_context?

        parameters.drop(skip)
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
