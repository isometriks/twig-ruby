# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {},
        config: {},
      },

      # date_default_timezone_set('UTC');
      # $twig->getExtension(\Twig\Extension\CoreExtension::class)->setDateFormat('Y-m-d', '%d days %h hours');
      # return [
      #     'date2' => new \DateInterval('P2D'),
      # ]
    ]
  end
end
