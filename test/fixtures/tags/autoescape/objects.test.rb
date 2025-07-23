# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          user: UserForAutoEscapeTest.new,
        },
        config: {},
      },
    ]
  end
end

class UserForAutoEscapeTest
  def name
    'Fabien<br />'
  end

  def to_s
    'Fabien<br />'
  end
end
