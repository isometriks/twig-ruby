# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: lambda { |twig|
          {
            foo: twig.load('foo.twig'),
          }
        },
        config: {},
      },
    ]
  end
end
