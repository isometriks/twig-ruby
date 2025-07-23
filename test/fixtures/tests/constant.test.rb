# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          value: 'bar',
          object: TwigTestFoo.new,
        },
        config: {},
        gsub: {
          fixture: [
            %w[E_NOTICE RUBY_ENGINE],
            %w[8 'ruby'], # rubocop:disable Lint/PercentStringArray
          ],
        },
      },
    ]
  end
end
