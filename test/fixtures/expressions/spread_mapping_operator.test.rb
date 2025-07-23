# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          morePersonalDetails: { favoriteColor: 'orange' },
          iterablePersonalDetails: { favoriteShoes: 'barefoot' },
        },
        config: {},
      },
    ]
  end
end
