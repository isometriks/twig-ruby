# frozen_string_literal: true

module Twig
  module Runtime
    # The output of an escaping strategy. It is html_safe like any SafeBuffer,
    # but it also remembers the strategy that produced it, so autoescaping only
    # lets it through for a strategy it is safe for. Twig's escape filter
    # returns a plain string, which autoescaping escapes again, while a plain
    # html_safe string is Markup that every strategy prints as is.
    class Escaped < ActiveSupport::SafeBuffer
      # Strategies whose output is also safe for other strategies, as the safe
      # analysis sees them
      IMPLIED_STRATEGIES = {
        html_attr: %i[html html_attr_relaxed],
        html_attr_relaxed: %i[html],
      }.freeze

      # @param [Array<Symbol>] strategies
      # @return [Array<Symbol>] The strategies and the ones they imply
      def self.with_implied(strategies)
        strategies | strategies.flat_map { |strategy| IMPLIED_STRATEGIES.fetch(strategy, []) }
      end

      # @return [Symbol]
      attr_reader :strategy

      # A SafeBuffer escapes unsafe strings it is given for HTML, so a new
      # buffer made without a strategy (by SafeBuffer#% for one) is only safe
      # for HTML.
      def initialize(string = '', strategy = :html)
        super(string)

        @strategy = strategy
      end

      # @param [Symbol] strategy
      def safe_for?(strategy)
        html_safe? && (self.strategy == strategy || IMPLIED_STRATEGIES.fetch(self.strategy, []).include?(strategy))
      end

      # A SafeBuffer escapes what it is given for HTML, so adding to an escaped
      # value keeps its strategy only when the addition is safe for it as well
      %i[concat << insert prepend replace safe_concat].each do |method|
        define_method(method) do |*args|
          added(args.last)

          super(*args)
        end
      end

      def []=(*args)
        added(args.last)

        super
      end

      def bytesplice(*args)
        added(args.last)

        super
      end

      # A repeat of an escaped value is escaped like it, where SafeBuffer would
      # make it Markup
      def *(other)
        rewrap(super, strategy)
      end

      # Part of an escaped value can end inside an escape sequence, so like a
      # SafeBuffer it is only safe for HTML, rather than Markup
      %i[[] chr].each do |method|
        define_method(method) do |*args|
          rewrap(super(*args), :html)
        end
      end

      alias slice []

      # What is left can also end inside an escape sequence
      def slice!(*args)
        @strategy = :html

        rewrap(super, :html)
      end

      private

      # @param [Object] value
      def added(value)
        return if value.nil? || !html_safe?
        return if value.html_safe? && (!value.is_a?(Escaped) || value.safe_for?(strategy))

        @strategy = :html
      end

      # @param [String, nil] value
      # @param [Symbol] strategy
      def rewrap(value, strategy)
        return value unless value.is_a?(ActiveSupport::SafeBuffer) && value.html_safe? && !value.equal?(self)

        Escaped.new(value, strategy)
      end
    end
  end
end
