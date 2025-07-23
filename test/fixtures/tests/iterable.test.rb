# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          foo: [],
          traversable: [].each,
          obj: TwigTestObj.new,
          val: 'test',
        },
        config: {},
      },
    ]
  end
end
