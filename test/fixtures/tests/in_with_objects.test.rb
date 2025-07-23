# frozen_string_literal: true

class Data
  def self.examples
    foo = TwigTestFoo.new
    foo1 = TwigTestFoo.new

    [
      {
        data: {
          object: foo,
          object_list: [foo1, foo],
        },
        config: {},
      },
    ]
  end
end
