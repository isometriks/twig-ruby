# frozen_string_literal: true

class Data
  def self.examples
    items = [
      { bar: 'foo', 'foo' => 'bar' },
      { 'foo' => 'foo', bar: 'bar' },
    ]

    [
      {
        data: {
          array: items,
          traversable: items.each,
        },
        config: {},
      },
    ]
  end
end
