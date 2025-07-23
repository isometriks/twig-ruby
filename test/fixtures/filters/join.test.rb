# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          foo: TwigTestFoo.new,
          bar: [3, 4],
        },
        config: {},
      },
    ]
  end
end
