# frozen_string_literal: true

class TestClassForMagicCallAttributes
  def bar
    'bar_from_getbar'
  end

  def respond_to_missing?(method, include_private = false)
    method == :foo || super
  end

  def method_missing(method, *args)
    if method == :foo
      return 'foo_from_call'
    end

    super
  end
end

class Data
  def self.examples
    [
      {
        data: {
          foo: TestClassForMagicCallAttributes.new,
        },
        config: {},
      },
    ]
  end
end
