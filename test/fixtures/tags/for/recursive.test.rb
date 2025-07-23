# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          sitemap: [
            {
              title: 'foo',
            },
            {
              title: 'bar',
            },
            {
              title: 'foobar',
            },
            {
              title: 'subsitemap',
              children: [
                {
                  title: 'foobar',
                },
                {
                  title: 'baz',
                },
              ],
            },
            {
              title: 'foobar',
            },
            {
              title: 'baz',
            },
          ],
        },
        config: {},
      },
    ]
  end
end
