# frozen_string_literal: true

class Data
  def self.examples
    c = {}

    [
      {
        data: {
          bar: 'bar',
          foo: { bar: 'bar' },
          array_access: { a: 'b' },
          object_storage: { c => 'foo' },
          object: c,
          indices_1: { 1 => 'first', 0 => 'second' },
          indices_2: { 1 => 'first', 'foo' => 'second', 2 => 'third' },
        },
        config: {},
        gsub: {
          fixture: [
            ['bar == foo', "bar == foo ? 'true' : ''"], # False shows up as nothing in Twig php
            # The rest of these are because of difference between string key / integer key,
            # php doesn't care about the difference, but Ruby does
            ['trad == trad2', 'trad|values == trad2|values'],
            ["'0'", '0'],
            ["'1'", '1'],
            ["'2'", '2'],
          ],
        },
      },
      {
        data: {
          bar: 'bar',
          foo: { bar: 'bar' },
          array_access: { a: 'b' },
          object: c,
          indices_1: { 1 => 'first', 0 => 'second' },
          indices_2: { 1 => 'first', 'foo' => 'second', 2 => 'third' },
        },
        config: { strict_variables: false },
        gsub: {
          fixture: [
            ['bar == foo', "bar == foo ? 'true' : ''"], # False shows up as nothing in Twig php
            # The rest of these are because of difference between string key / integer key,
            # php doesn't care about the difference, but Ruby does
            ['trad == trad2', 'trad|values == trad2|values'],
            ["'0'", '0'],
            ["'1'", '1'],
            ["'2'", '2'],
          ],
        },
      },
    ]
  end
end
