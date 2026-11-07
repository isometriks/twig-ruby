# frozen_string_literal: true

class TwigTestStringy
  def initialize(value)
    @value = value
  end

  def to_s
    @value
  end
end

class TwigTestHolder
  attr_reader :name, :stringable

  def initialize
    @name = 'attr'
    @stringable = TwigTestStringy.new('attr_obj')
  end

  def getStringable # rubocop:disable Naming/MethodName
    TwigTestStringy.new('method_obj')
  end
end

class Data
  def self.examples
    [
      {
        data: { 'obj' => TwigTestStringy.new('ctx_obj'), 'holder' => TwigTestHolder.new },
        config: {},
      },
    ]
  end
end
