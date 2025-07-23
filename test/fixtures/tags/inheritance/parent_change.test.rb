# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          foo: true,
        },
        config: {},
      },
      {
        data: {
          foo: false,
        },
        config: {},
      },
    ]
  end
end
