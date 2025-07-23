# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          empty_it: [],
          yielding_it: [].each,
        },
        config: {},
      },
    ]
  end
end
