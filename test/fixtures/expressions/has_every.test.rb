# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: { it: [0, 2, 4].each },
        config: {},
        gsub: {
          # Hash keys are symbols not strings
          fixture: [
            ['"d" > k', '"d" > k.to_s'],
          ],
        },
      },
    ]
  end
end
