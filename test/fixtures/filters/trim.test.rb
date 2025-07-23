# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          text: '  If you have some <strong>HTML</strong> it will be escaped.  ',
        },
        config: {},
      },
    ]
  end
end
