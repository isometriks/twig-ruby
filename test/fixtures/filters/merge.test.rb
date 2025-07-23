# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          items: {
            foo: 'bar',
          },
          numerics: [1, 2, 3],
          traversable: {
            a: [1, 2, 3],
            b: {
              a: 'b',
            },
          },
        },
        config: {},
      },
    ]
  end
end
