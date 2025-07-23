# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: lambda { |twig|
          {
            included_loaded: twig.load('included.twig'),
            included_loaded_internal: twig.load('included.twig'),
          }
        },
        config: {},
      },
    ]
  end
end
