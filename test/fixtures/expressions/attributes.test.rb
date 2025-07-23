# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          # Modified since Ruby doesn't have a .timezone for dates
          date: Class.new do
            def timezone
              'Europe/Paris'
            end
          end.new,
          property: Struct.new(:foo).new('bar'),
        },
        config: {},
      },
    ]
  end
end
