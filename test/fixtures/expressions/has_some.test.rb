# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: { it: [1, 2, 3].each },
        config: {},
        gsub: {
          fixture: [
            ['"b" == k', '"b" == k.to_s'],
          ],
        },
      },
    ]
  end
end
