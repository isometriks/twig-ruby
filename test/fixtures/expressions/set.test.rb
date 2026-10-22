# frozen_string_literal: true

class TwigTestUserObj
  def name
    'Fabien'
  end
end

class Data
  def self.examples
    [
      {
        data: {
          'user' => { 'name' => 'Fabien', 'email' => 'fabien@example.com' },
          'user_map' => { 'first_name' => 'Fabien', 'last_name' => 'Potencier' },
          'user_obj' => TwigTestUserObj.new,
          'null_obj' => nil,
        },
        config: {},
      },
    ]
  end
end
