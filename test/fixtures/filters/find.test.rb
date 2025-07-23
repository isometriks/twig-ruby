# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          it: { 'a' => 1, 'b' => 2, 'c' => 5, 'd' => 8 },
          ita: { 'a' => 1, 'b' => 2, 'c' => 5, 'd' => 8 },
          xml: %w[foo bar], # Not really relevant
        },
        config: {},
        gsub: {
          fixture: [
            ['k != "c"', 'k != :c'],
          ],
        },
      },
    ]
  end
end
