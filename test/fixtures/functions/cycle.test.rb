# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          array1: %w[odd even],
          array2: %w[apple orange citrus],
          array3: [1, 2, false, nil],
        },
        config: {},
      },
    ]
  end
end
