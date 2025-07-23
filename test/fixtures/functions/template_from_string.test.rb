# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          name: 'Fabien',
          template: 'Hello {{ name }}',
        },
        config: {},
      },
    ]
  end
end
