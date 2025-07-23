# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          items: {
            a: %w[a1 a2 a3],
            b: ['b1'],
          },
        },
        config: {},
      },
    ]
  end
end
