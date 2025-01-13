module Twig
  class AutoHash < Hash
    def add(*values)
      values.each do |value|
        self[self.length] = value
      end
    end
  end
end
