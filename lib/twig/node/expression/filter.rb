# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class Filter < Call
        # @param [Node::Base] node
        # @param [TwigFilter|Constant] filter
        def initialize(node, filter, arguments, lineno)
          if filter.is_a?(TwigFilter)
            name = filter.name
            filter_name = Constant.new(name, lineno)
          else
            name = filter.attributes[:value]
            filter_name = filter
          end

          super({
            node:,
            filter: filter_name,
            arguments:,
          }, {
            name:,
            type: :filter,
          }, lineno)

          if filter.is_a?(TwigFilter)
            attributes[:twig_callable] = filter
          end
        end

        def compile(compiler)
          name = nodes[:filter].attributes[:value]

          if name != attributes[:name]
            raise 'Changing the value of a "filter" node is not supported'
          end

          if name == 'raw'
            raise 'Cannot create raw filter via expression'
          end

          unless attributes.key?(:twig_callable)
            attributes[:twig_callable] = compiler.environment.filter(name)
          end

          compile_callable(compiler)
        end
      end
    end
  end
end
