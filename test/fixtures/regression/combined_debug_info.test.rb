# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          foo: 'foo',
        },
        config: {},
        gsub: {
          exception: [
            %w[string String],
          ],
        },
      },
    ]
  end
end
