# frozen_string_literal: true

class Data
  def self.examples
    iter = %w[bar foo].each

    [
      {
        data: {
          string_empty: '',
          string_zero: '0',
          value_null: nil,
          value_false: false,
          value_int_zero: 0,
          array_empty: [],
          array_not_empty: [1, 2],
          magically_callable: [1, 2], # Just put a real array here, I don't think this is useful for Ruby
          countable_empty: TwigCountableStub.new(0),
          countable_not_empty: TwigCountableStub.new(2),
          tostring_empty: TwigToStringStub.new(''),
          tostring_not_empty: TwigToStringStub.new('0'), # edge case of using "0" as the string
          markup_empty: ''.html_safe,
          markup_not_empty: 'test'.html_safe,
          iterator: iter,
          empty_iterator: [].each,
          callback_iterator: iter.filter { |_el| true },
          empty_callback_iterator: iter.filter { |_el| false },
        },
        config: {},
      },
    ]
  end
end
