# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          key: MyObj.new,
        },
        config: {},
      },
    ]
  end
end

class MyObj
  def to_s
    'foo'
  end
end
