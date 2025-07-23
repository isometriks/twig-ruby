# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          traversable: {
            '%this%': 'foo',
            '%that%': 'bar',
          },
        },
        config: {},
      },
    ]
  end
end
