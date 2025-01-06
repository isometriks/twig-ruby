module Twig
  # Base class for compiled templates
  class Template
    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
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

    private

    # @return [Environment]
    def env
      @environment
    end
  end
end
