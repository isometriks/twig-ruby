# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: { 'value' => (+"\xC3\x28abc").force_encoding('UTF-8') },
        config: {},
      },
    ]
  end
end
