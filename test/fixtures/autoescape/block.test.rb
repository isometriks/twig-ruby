# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: { br: '<br />' },
        config: { autoescape: 'name' },
      },
    ]
  end
end
