# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          bar: 'OK',
          foo: { bar: 'OK' },
          obj: TwigTestFoo.new,
          tag: '<br>',
        },
        config: {},
      },
    ]
  end
end
