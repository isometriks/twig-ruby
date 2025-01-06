module Twig
  # Base class for compiled templates
  class Template
    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
      @parents = {}
      @blocks = {}
    end

    def call(context = {})
      raise "call is not implemented"
    end

    def render(context = {})
      parts = []

      self.call(context.transform_keys(&:to_sym)) do |yielded|
        parts << yielded
      end

      parts.join
    end

    def yield_block(name)
      parts = []

      public_send(:"block_#{name}") do |yielded|
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
