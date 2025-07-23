# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          obj: TwigTestFoo.new,
          method: 'foo',
          array: { foo: 'bar' },
          item: 'foo',
          nonmethod: 'xxx',
          arguments: %w[a b],
        },
        config: {},
      },
    ]
  end
end
