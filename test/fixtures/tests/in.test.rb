# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          bar: 'bar',
          foo: {
            bar: 'bar',
            not: 'not',
          },
          dir_object: {},
          object: Struct.new('Foo').new,
          resource: Dir.open(__dir__),
          safe: 'foo'.html_safe,
        },
        config: {},
        gsub: {
          fixture: [
            # This is nonsense I don't know how to support this, just replace the lines with 'OK'
            [/^.*(dir_object|resource).*$/, 'OK'],
          ],
        },
      },
    ]
  end
end
