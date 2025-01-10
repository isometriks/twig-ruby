module Twig
  # Base class for compiled templates
  class Template
    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
      @parents = {}
      @blocks = {}
    end

    def call(context = {}, blocks = {})
      raise "call is not implemented"
    end

    def render(context = {}, blocks = {})
      parts = []

      self.call(context.transform_keys(&:to_sym), blocks) do |yielded|
        parts << yielded
      end

      parts.join
    end

    def yield_block(name, context = {}, blocks = {})
      parts = []
      object = self

      if blocks.key?(name)
        object = blocks[name]
      end

      object.public_send(:"block_#{name}", context, blocks) do |yielded|
        parts << yielded
      end

      parts.join
    end

    private

    # @param [String] name
    # @return ]Template]
    def load_template(name, template_name = '', template_line = nil)
      env.load_template(name)
    end

    # @return [Environment]
    def env
      @environment
    end
  end
end
