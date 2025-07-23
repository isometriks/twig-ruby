# frozen_string_literal: true

module Twig
  module Runtime
    class LoopIterator
      attr_reader :index0, :previous, :next

      def initialize(seq)
        @seq = Runtime::EnumerableHash.from(seq).to_enum
        @index0 = 0
        @previous = nil
        @next = nil
      end

      def each(&)
        @index0 = 0

        loop do
          current = @seq.next

          begin
            @next = @seq.peek
          rescue StopIteration
            @next = nil
          end

          yield current[0], current[1]
          @index0 += 1
          @previous = current
        rescue StopIteration
          break
        end
      end

      def first
        @index0.zero?
      end

      def last
        revindex0.zero? || length.zero?
      end

      def length
        @length ||= @seq.count
      end

      def index
        @index0 + 1
      end

      def revindex0
        [0, length - index].max
      end

      def revindex
        revindex0 + 1
      end
    end
  end
end
