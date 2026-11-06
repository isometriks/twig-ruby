# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          expect: RUBY_ENGINE,
          # Like the fixture's ArrayObject, TwigTestFoo has ARRAY_AS_PROPS = 2
          object: TwigTestFoo.new,
        },
        config: {},
        gsub: {
          fixture: [
            %w[DATE_W3C RUBY_ENGINE],
          ],
          result: [
            %w[ArrayObject TwigTestFoo],
          ],
        },
      },
    ]
  end
end
