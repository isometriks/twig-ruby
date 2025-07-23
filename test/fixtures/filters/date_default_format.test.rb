# frozen_string_literal: true

class Data
  def self.examples
    # @todo not really complete
    # date_default_timezone_set('UTC');
    # $twig->getExtension(\Twig\Extension\CoreExtension::class)->setDateFormat('Y-m-d', '%d days %h hours');
    [
      {
        data: lambda { |twig|
          twig.extension(Twig::Extension::Core).date_format = '%Y-%m-%d'

          {
            date1: DateTime.new(2010, 10, 4, 13, 45, 0, '+00:00'),
          }
        },
        config: {},
        gsub: {
          fixture: [
            %w[d/m/Y %d/%m/%Y],
          ],
        },
      },
    ]
  end
end
