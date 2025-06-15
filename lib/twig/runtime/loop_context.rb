# frozen_string_literal: true

##
# This file is part of Twig.
#
# (c) Fabien Potencier
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

module Twig
  module Runtime
    class LoopContext
      # @return [Object, nil] The parent context
      attr_reader :parent

      delegate :index0, :index, :revindex0, :revindex, :length, :first, :last, to: :loop

      def initialize(loop, parent, blocks, recurse_func, depth)
        @loop = loop
        @parent = parent
        @blocks = blocks
        @recurse_func = recurse_func
        @depth = depth
      end

      # @param value [Object] The first value in the cycle
      # @param values [Array<Object>] The rest of the values in the cycle
      # @return [Object] The current value in the cycle
      def cycle(value, *values)
        values.unshift(value)
        values[index0 % values.length]
      end

      # Recursion function
      # @param iterator [Enumerable] The iterator
      # @return [Enumerator] An enumerator for recursive iteration
      def call(iterator)
        if @depth > 50
          raise 'Nesting level too deep.'
        end

        @parent.buffer_and_return do
          @recurse_func.call(LoopIterator.new(iterator), @parent, @blocks, @recurse_func, @depth + 1)
        end
      end

      # @return [Integer] The depth starting from 0
      def depth0
        @depth
      end

      # @return [Integer] The depth starting from 1
      def depth
        @depth + 1
      end

      private

      attr_reader :loop
    end
  end
end
