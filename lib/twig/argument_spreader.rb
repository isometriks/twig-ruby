# frozen_string_literal: true

module Twig
  class ArgumentSpreader
    # @param [Method] method
    def initialize(method)
      @method = method
    end

    # @todo Read method arguments and try to match kwargs to positional args
    # like {{ ["Hello", "World"] | join(glue: " ") }}
    def call(*arguments, **kwargs)
      positional = []

      arguments.each do |v|
        if v.is_a?(Spread)
          if v.array?
            positional = [*positional, *v.value]
          else
            kwargs = kwargs.merge(v.value)
          end
        else
          positional << v
        end
      end

      kwargs = kwargs.transform_keys(&:to_sym)

      if positional.empty? && kwargs.empty?
        method.call
      elsif positional.length.positive? && kwargs.empty?
        method.call(*positional)
      elsif positional.empty? && kwargs.length.positive?
        method.call(**kwargs)
      elsif positional.length.positive? && kwargs.length.positive?
        method.call(*positional, **kwargs)
      end
    end

    private

    # @return [Method]
    attr_reader :method
  end
end
