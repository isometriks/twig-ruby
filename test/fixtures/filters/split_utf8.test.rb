# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          foo: 'Ä,é,Äほ',
          baz: 'éÄßごa',
        },
        config: {},
      },
    ]
  end
end
