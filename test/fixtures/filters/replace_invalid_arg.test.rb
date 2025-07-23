# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          stdClass: TwigTestFoo.new,
        },
        config: {},
        gsub: {
          exception: [
            %w[stdClass TwigTestFoo],
          ],
        },
      },
    ]
  end
end
