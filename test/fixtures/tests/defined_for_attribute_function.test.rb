# frozen_string_literal: true

class Data
  def self.examples
    data = {
      'nested' => { 'definedVar' => 'defined' },
      'definedVarName' => 'definedVar',
      'undefinedVarName' => 'undefinedVar',
    }

    [
      {
        data:,
        config: {},
      },
      {
        data:,
        config: { strict_variables: false },
      },
    ]
  end
end
