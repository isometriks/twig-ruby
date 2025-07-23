# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          text: '<p>Hello, <strong>World</strong>!</p>',
        },
        config: {},
        gsub: {
          # Sanitize gem adds spaces between tags, I don't think this needs to break parity
          output: [
            [/^ /, ''],
            [/ $/, ''],
          ],
        },
      },
    ]
  end
end
