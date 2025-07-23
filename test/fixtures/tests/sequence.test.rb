# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          empty: [],
          sequence: %w[foo bar baz],
          empty_array_obj: [], # Don't have ArrayObject to test
          sequence_array_obj: %w[foo bar], # new \ ArrayObject(['foo', 'bar' ]),
          mapping_array_obj: { foo: 'bar' }, # new \ ArrayObject([foo : 'bar']),
          obj: Struct.new('Foo').new,
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
