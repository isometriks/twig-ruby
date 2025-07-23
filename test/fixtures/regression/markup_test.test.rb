# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {
          spaces: '    '.html_safe, # Twig::Markup.new('    ', 'UTF-8'),
          empty: ''.html_safe, # Twig::Markup.new('', 'UTF-8')
        },
        config: {},
      },
    ]
  end
end
