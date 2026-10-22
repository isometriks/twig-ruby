# frozen_string_literal: true

class TwigTestUserObj
  def name
    'Fabien'
  end
end

class TwigTestPairTraversable
  include Enumerable

  attr_reader :yielded

  def initialize
    @yielded = 0
  end

  def each
    { 5 => 'Fabien', 8 => 'Potencier', 13 => 'Ignored' }.each_value do |value|
      @yielded += 1
      yield value
    end
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
          'pair_traversable' => TwigTestPairTraversable.new,
          'short_traversable' => ['one'].each,
        },
        config: {},
      },
    ]
  end
end
