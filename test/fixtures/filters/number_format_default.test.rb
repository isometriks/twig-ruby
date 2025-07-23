# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: lambda do |twig|
          twig.extension(Twig::Extension::Core).number_format = [2, '!', '=']

          {}
        end,
        config: {},
      },
    ]
  end
end
