# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          items: { a: 'a', b: 'b', c: 'c', d: 'd', 123 => 'e' },
        },
        config: {},
      },
    ]
  end
end
