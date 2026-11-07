# frozen_string_literal: true

module Twig
  module Runtime
    # Calls a method with arguments that include a spread, unpacking each one
    # as PHP 8.1 unpacks an array into a call (see Spread.split_arguments).
    class ArgumentSpreader
      # The parameters PHP would bind a positional or named argument to. A
      # keyword parameter counts, as Twig callables take their optional
      # arguments as keywords (like join's glue)
      SLOT_TYPES = %i[req opt key keyreq].freeze

      # @param [Method, Proc] method
      # @param [Hash{String => Symbol}, nil] names for a Twig callable, the
      #   Ruby parameter of each Twig argument name that differs from it. A
      #   name unpacked from a spread is then bound to the parameter of that
      #   name, as PHP binds a named argument, even to a positional one. With
      #   nil, as for a helper method, it is passed as a Ruby keyword.
      def initialize(method, names = nil)
        @method = method
        @names = names
      end

      # like {{ ["Hello", "World"] | join(glue: " ") }}
      def call(*arguments, **kwargs, &)
        positional, named = Spread.split_arguments(arguments)

        if @names
          positional, kwargs = bind(positional, named, kwargs)
        else
          named.each { |name, value| add_keyword(kwargs, name.to_sym, name, value) }
        end

        method.call(*positional, **kwargs, &)
      end

      private

      # @return [Method]
      attr_reader :method

      # Binds the arguments to the parameters as PHP binds them: the
      # positional arguments to the parameters in order, keyword parameters
      # included, then each name to its parameter. The compiler passes the
      # arguments it binds to keyword parameters as keywords, so those come
      # before the spreads.
      #
      # @return [Array(Array, Hash{Symbol => Object})]
      def bind(positional, named, kwargs)
        slots = {}
        kwargs = kwargs.reject do |key, value|
          index = slot_index_of(key)
          slots[index] = value if index

          index
        end

        extra = bind_positional(positional, slots)

        named.each do |name, value|
          index = slot_index(name)

          if index
            raise ArgumentError, "Named parameter $#{name} overwrites previous argument" if slots.key?(index)

            slots[index] = value
          elsif parameters.any? { |type, _| type == :keyrest }
            add_keyword(kwargs, name.to_sym, name, value)
          else
            raise ArgumentError, "Unknown named parameter $#{name}"
          end
        end

        [positional_arguments(slots) + extra, slot_keywords(slots).merge(kwargs)]
      end

      # Fills the slots in order with the positional arguments. With a rest
      # parameter, as in PHP, they only fill the positional parameters.
      #
      # @return [Array] the arguments left over, for the rest parameter or for
      #   Ruby to report
      def bind_positional(positional, slots)
        rest = parameters.any? { |type, _| type == :rest }
        index = 0

        positional.each_with_index do |value, position|
          index += 1 while slots.key?(index)
          return positional.drop(position) if index >= slot_parameters.length
          return positional.drop(position) if rest && !%i[req opt].include?(slot_parameters[index][0])

          slots[index] = value
        end

        []
      end

      # Ruby can't skip an optional positional parameter, as PHP does by
      # passing its default, so a name bound past a gap raises
      def positional_arguments(slots)
        positional_slots = slot_parameters.take_while { |type, _| %i[req opt].include?(type) }
        filled = positional_slots.each_index.select { |index| slots.key?(index) }
        count = filled.empty? ? 0 : filled.max + 1

        positional_slots.first(count).each_with_index.map do |(type, gap), index|
          next slots[index] if slots.key?(index)

          if type == :opt
            raise ArgumentError,
              "Argument \"#{argument_name(filled.find { |i| i > index })}\" could not be assigned because it " \
              'is mapped to a Ruby callable which cannot determine the default value of optional argument ' \
              "\"#{gap}\"; use a keyword parameter instead"
          end

          raise ArgumentError, "Argument ##{index + 1} ($#{gap}) not passed"
        end
      end

      def slot_keywords(slots)
        slots.each_with_object({}) do |(index, value), kwargs|
          type, name = slot_parameters[index]
          kwargs[name] = value if %i[key keyreq].include?(type)
        end
      end

      # @return [Integer, nil] the slot of the parameter a name binds to
      def slot_index(name)
        slot_index_of(@names.fetch(name) { name.to_sym })
      end

      def slot_index_of(parameter)
        slot_parameters.index { |_, name| name == parameter }
      end

      # @return [String] the name an argument for the slot is given by
      def argument_name(index)
        parameter = slot_parameters[index][1]

        @names.key(parameter) || parameter.to_s
      end

      def add_keyword(kwargs, key, name, value)
        raise ArgumentError, "Named parameter $#{name} overwrites previous argument" if kwargs.key?(key)

        kwargs[key] = value
      end

      def slot_parameters
        @slot_parameters ||= parameters.select { |parameter| SLOT_TYPES.include?(parameter.first) }
      end

      def parameters
        @parameters ||= method.parameters
      end
    end
  end
end
