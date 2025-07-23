# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {},
        config: {},
        gsub: {
          result: [
            %w[1990 1990.0],
          ],
        },
      },
    ]
  end
end
