module Twig
  # Base class for compiled templates
  class Template
    def initialize
      @parents = {}
      @blocks = {}
    end

    def call
      raise "call is not implemented"
    end

    def self.display
      parts = []
      new.call do |yielded|
        parts << yielded
      end

      parts.join
    end
  end
end
