# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          nested: {
            definedVar: 'defined',
          },
          definedVarName: 'definedVar',
          undefinedVarName: 'undefinedVar',
        },
        config: {},
      },
      {
        data: {
          nested: {
            definedVar: 'defined',
          },
          definedVarName: 'definedVar',
          undefinedVarName: 'undefinedVar',
        },
        config: {
          strict_variables: false,
        },
      },
    ]
  end
end
