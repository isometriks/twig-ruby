# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          empty: [],
          sequence: %w[foo bar baz],
          empty_array_obj: [],
          sequence_array_obj: %w[foo bar],
          mapping_array_obj: { foo: 'bar' },
          obj: {},
          mapping: {
            foo: 'bar',
            bar: 'foo',
          },
          string: 'test',
        },
        config: {},
      },
    ]
  end
end
