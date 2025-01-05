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
      new.call do |yielded|
        puts yielded
      end
    end
  end
end
