# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          'subject' => (+"\xC3\x28abc").force_encoding('UTF-8'),
          'regexp' => '/^\p{L}+$/u',
        },
        config: {},
      },
    ]
  end
end
