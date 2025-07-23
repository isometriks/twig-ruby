# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          array1: [4, 1],
          array2: %w[foo bar],
          traversable: {
            0 => 3,
            1 => 2,
            2 => 1,
          },
        },
        config: {},
      },
    ]
  end
end
