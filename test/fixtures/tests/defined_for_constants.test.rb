# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          object: TwigConstants.new,
        },
        config: {},
        gsub: {
          fixture: [
            %w[DATE_W3C RUBY_ENGINE],
          ],
        },
      },
    ]
  end
end
