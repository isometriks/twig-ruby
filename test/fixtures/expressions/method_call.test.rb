# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          foo: 'bar',
          items: { foo: TwigTestFoo.new, bar: 'foo' },
        },
        config: { strict_variables: false },
      },
    ]
  end
end
