# frozen_string_literal: true

module Twig
  module Error
    class Syntax < Error::Base
      # Appends the items that look like name, closest first, as in
      # ' Did you mean "upper"?', when there are any: those within a
      # Levenshtein distance of a third of the length of name, or that
      # contain it.
      #
      # @param [String] name the name of the item that does not exist
      # @param [Array<String, Symbol>] items the names of the items that do
      def add_suggestions(name, items)
        name = name.to_s
        alternatives = items.map(&:to_s).uniq.filter_map do |item|
          distance = self.class.levenshtein(name, item)

          [item, distance] if distance <= name.bytesize / 3.0 || item.include?(name)
        end

        return if alternatives.empty?

        alternatives = alternatives.each_with_index.sort_by { |(_, distance), index| [distance, index] }

        append_message(" Did you mean \"#{alternatives.map { |(item, _), _| item }.join('", "')}\"?")
      end

      # The Levenshtein distance between the bytes of a and b, as PHP's
      # levenshtein() computes it.
      #
      # @return [Integer]
      def self.levenshtein(a, b)
        a = a.bytes
        b = b.bytes
        previous = (0..b.length).to_a

        a.each_with_index do |a_byte, i|
          current = [i + 1]

          b.each_with_index do |b_byte, j|
            current << [previous[j + 1] + 1, current[j] + 1, previous[j] + (a_byte == b_byte ? 0 : 1)].min
          end

          previous = current
        end

        previous.last
      end
    end
  end
end
