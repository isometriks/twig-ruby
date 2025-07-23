# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          array: [1, 4],
          string: 'foo',
          number: 1000,
          to_string_able: TwigToStringStub.new('foobar'),
          countable: TwigCountableStub.new(42),
          iterator_aggregate: %w[a b c].each,
          null: nil,
          magic: TwigMagicCallStub.new,
          non_countable: Object.new,
          simple_xml_element: [0, 1], # Don't care about this XML
          iterator: TwigSimpleIteratorForTesting.new,
        },
        config: {},
      },
    ]
  end
end
