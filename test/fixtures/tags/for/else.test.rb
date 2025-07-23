# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          items: %w[a b],
        },
        config: {},
      },
      {
        data: {
          items: [],
        },
        config: {},
      },
      {
        data: {},
        config: {
          strict_variables: false,
        },
      },
    ]
  end
end
