# frozen_string_literal: true

class Data
  def self.examples
    [
      {
        data: {},
        config: {},
        # Template names are different, so we can substitute to still pass the test.
        gsub: {
          exception: [
            %w[85e7b092afbbcd36f11981c2ef8f1569 4900163d56b1af4b704c6b0afee7f98ba53418ce7a93d37a3af1882735baf9cd],
          ],
        },
      },
    ]
  end
end
