# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: { a: 4, b: -2 },
        config: {},
        # When using integers for powers, ruby will give back fractions, these are still correct though
        gsub: {
          result: [
            %w[-0.125 -1/8],
            %w[0.0625 1/16],
            %w[0.25 1/4],
          ],
        },
      },
    ]
  end
end
