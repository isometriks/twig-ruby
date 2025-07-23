# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          date1: Time.new(2010, 10, 4, 13, 45, 0, '+00:00'),
          date2: Time.new(2010, 10, 4, 13, 45, 0, '+00:00'),
          date3: '2010-10-04 13:45',
          date4: 1_286_199_900, # DateTime equivalent in UTC timestamp
          date5: -189_291_360,  # DateTime equivalent in UTC timestamp
        },
        config: {},
        gsub: {
          # Don't have a format method, use strftime, and also, use equivalent format
          fixture: [
            %w[format('r') rfc2822],
            ["date('-1day')", 'date().prev_day'],
          ],
        },
      },
    ]
  end
end
