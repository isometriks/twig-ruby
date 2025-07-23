# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          item: ['1', '2', ['3.1', %w[3.2.1 3.2.2], '3.4']],
        },
        config: {},
      },
    ]
  end
end
