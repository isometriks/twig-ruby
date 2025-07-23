# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: { markup: 'test'.html_safe },
        config: {},
        # False shows up as 0 in Twig PHP
        gsub: {
          result: [
            ['0', ''],
          ],
        },
      },
    ]
  end
end
