# frozen_string_literal: true

class Data
  def self.examples
    foo = TwigTestFoo.new
    bar = TwigTestFoo.new

    [
      {
        data: {
          foo:,
          iter: [bar, foo].each,
        },
        config: {},
      },
    ]
  end
end
