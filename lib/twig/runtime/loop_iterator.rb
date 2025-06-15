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
    class LoopIterator
      attr_reader :index0

      def initialize(seq)
        @seq = Extension::Core.ensure_hash(seq)
        @index0 = 0
      end

      def each(&)
        @index0 = 0
        @seq.each do |k, v|
          yield k, v
          @index0 += 1
        end
      end

      def first
        @index0.zero?
      end

      def last
        revindex0.zero?
      end

      def length
        @length ||= @seq.length
      end

      def index
        @index0 + 1
      end

      def revindex0
        length - index
      end

      def revindex
        revindex0 + 1
      end
    end
  end
end
