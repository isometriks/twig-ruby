# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: lambda { |twig|
          ::Time.zone = ::Time.find_zone 'Europe/Paris'
          twig.extension(Twig::Extension::Core).timezone = 'UTC'

          {
            date1: Time.zone.local(2010, 10, 4, 13, 45, 0),
            date2: Time.zone.local(2010, 10, 4, 13, 45, 0),
            date3: '2010-10-04 13:45',
            date4: 1_286_199_900, # Unix timestamp - always GMT
            date5: -189_291_360, # Unix timestamp for 1964-01-02 03:04 UTC
            date6: Time.find_zone('America/New_York').local(
              2010, 10, 4, 13, 45, 0
            ),
            date7: '2010-01-28T15:00:00+04:00',
            timezone1: 'America/New_York',
          }
        },
        config: {},
        gsub: {
          fixture: [
            ['d/m/Y H:i:s', '%d/%m/%Y %H:%M:%S'],
            %w[d/m/Y %d/%m/%Y],
            %w['e' '%Z'], # rubocop:disable Lint/PercentStringArray
          ],
          output: [
            %w[CEST Europe/Paris],
            %w[EDT America/New_York],
          ],
        },
      },
    ]
  end
end
