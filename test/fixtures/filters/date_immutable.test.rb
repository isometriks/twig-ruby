# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {},
        config: {},
      },
    ]

    # @todo timezones
    # date_default_timezone_set('Europe/Paris');
    # return [
    #     'date1' => new \DateTimeImmutable('2010-10-04 13:45'),
    #     'date2' => new \DateTimeImmutable('2010-10-04 13:45', new \DateTimeZone('America/New_York')),
    #     'timezone1' => new \DateTimeZone('America/New_York'),
    # ]
  end
end
