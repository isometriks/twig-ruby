# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          entries: [
            {
              category: 'cat1',
              message: 'Cat1 message',
            },
            {
              category: 'cat1',
              message: 'Another cat1 message',
            },
            {
              category: 'cat2',
              message: 'Cat2 message',
            },
            {
              category: 'cat3',
              message: 'Yet another category of messages',
            },
          ],
        },
        config: {},
      },
    ]
  end
end
