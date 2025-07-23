# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          foo: 'bar<br />',
        },
        config: {},
      },
    ]
  end
end
