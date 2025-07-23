# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          fruits: [
            {
              'name' => 'Apples',
              quantity: 5,
            },
            {
              'name' => 'Oranges',
              quantity: 2,
            },
            {
              'name' => 'Grapes',
              quantity: 4,
            },
          ],
        },
        config: {},
      },
    ]
  end
end
