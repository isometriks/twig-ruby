# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          foo: 'foo',
          bar: 'bar',
        },
        config: {
          debug: true,
          autoescape: false,
        },
      },
    ]
  end
end
