# frozen_string_literal: true

class Data
  # Stands in for the PHP fixture's ArrayObject: iterable, but not a Hash
  class ArrayObject
    include Enumerable

    def initialize(values)
      @values = values
    end

    def each(&)
      @values.each(&)
    end
  end

  def self.examples
    [
      {
        data: {
          vars: ArrayObject.new({
            foo: 'baz',
            bar: 'qux',
          }),
        },
        config: {},
      },
    ]
  end
end
