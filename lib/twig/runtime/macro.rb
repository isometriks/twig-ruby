# frozen_string_literal: true

module Twig
  module Runtime
    # A compiled macro: its body as a lambda and the signature declared in the template.
    #
    # Arguments are bound by name into a Hash that is handed to the body, so an argument
    # name never becomes a Ruby identifier (`class`, `GET` and the like are fine).
    class Macro
      # @return [String]
      attr_reader :name

      # @param [String] name
      # @param [Proc] body Called with the caller's call_context and the Hash of bound arguments
      # @param [Hash{String => Boolean}] arguments The declared argument names, in definition
      #   order, mapped to whether they have a default value
      # @param [String, nil] variadic
      def initialize(name, body, arguments = {}, variadic = nil)
        @name = name
        @body = body
        @arguments = arguments
        @variadic = variadic
        @argument_indexes = arguments.each_key.with_index.to_h
      end

      # @param [Hash{Integer, String => Object}] arguments Positional arguments keyed by their
      #   position, named arguments keyed by their name
      # @param [Object, nil] call_context
      # @param [Source] source
      # @param [Integer] lineno
      def call(arguments, call_context, source, lineno)
        positional, named = split_arguments(arguments, source, lineno)
        names = @arguments.keys
        bound = {}
        extra = AutoHash.new

        positional.each_with_index do |value, index|
          if index < names.length
            bound[names[index]] = value
          else
            extra.add(value)
          end
        end

        named.each do |key, value|
          if (index = @argument_indexes[key]).nil?
            extra[key] = value
          elsif index < positional.length
            raise Error::Runtime.new("Argument \"#{key}\" is defined twice for macro \"#{@name}\".", lineno, source)
          else
            bound[key] = value
          end
        end

        bound['varargs'] = extra

        @body.call(call_context, bound)
      end

      private

      # Spreads are expanded in place, like PHP's array unpacking: a sequence adds positional
      # arguments, and a mapping adds a positional argument for each integer key and a named
      # one for any other key.
      #
      # @return [Array(Array, Hash)]
      def split_arguments(arguments, source, lineno)
        positional = []
        named = {}
        add = lambda do |key, value|
          if key.is_a?(Integer)
            check_positional(named, source, lineno)
            positional << value
          else
            named[key.to_s] = value
          end
        end

        arguments.each do |key, value|
          if !value.is_a?(Spread)
            add.call(key, value)
          elsif value.value.is_a?(::Hash)
            value.value.each { |k, v| add.call(k, v) }
          elsif value.value.is_a?(Enumerable)
            check_positional(named, source, lineno)
            positional.concat(value.value.to_a)
          else
            raise Error::Runtime.new(
              "Only sequences and mappings can be spread into the arguments of macro \"#{@name}\".",
              lineno,
              source
            )
          end
        end

        [positional, named]
      end

      def check_positional(named, source, lineno)
        return if named.empty?

        raise Error::Runtime.new(
          "Positional arguments cannot be used after named arguments for macro \"#{@name}\".",
          lineno,
          source
        )
      end
    end
  end
end
