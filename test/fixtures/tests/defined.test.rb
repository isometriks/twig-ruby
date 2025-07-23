# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          definedVar: 'defined',
          zeroVar: 0,
          nullVar: nil,
          nested: {
            definedVar: 'defined',
            zeroVar: 0,
            nullVar: nil,
            definedArray: [0],
          },
          object: TwigTestFoo.new,
        },
        config: {},
      },
      {
        data: {
          definedVar: 'defined',
          zeroVar: 0,
          nullVar: nil,
          nested: {
            definedVar: 'defined',
            zeroVar: 0,
            nullVar: nil,
            definedArray: [0],
          },
          object: TwigTestFoo.new,
        },
        config: {
          strict_variables: false,
        },
      },
    ]
  end
end
