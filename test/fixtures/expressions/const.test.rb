# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: { foo: TwigTestFoo.new },
        config: { strict_variables: false },
      },
    ]
  end
end
