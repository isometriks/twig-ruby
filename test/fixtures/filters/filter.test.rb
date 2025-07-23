# frozen_string_literal: true

class Data
  class Xml
    include Enumerable

    def each(&)
      yield 'elem', 'foo'
      yield 'elem', 'bar'
      yield 'elem', 'baz'
    end
  end

  def self.examples
    [
      {
        data: {
          it: { a: 1, b: 2, c: 5, d: 8 },
          ita: { a: 1, b: 2, c: 5, d: 8 },
          xml: Xml.new,
        },
        config: {},
        gsub: {
          fixture: [
            ['k != "d"', 'k != :d'],
          ],
        },
      },
    ]
  end
end
