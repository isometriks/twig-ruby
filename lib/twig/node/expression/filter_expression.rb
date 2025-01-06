module Twig
  module Node
    module Expression
      class FilterExpression < CallExpression
        # @param [Node] node
        # @param [Filter|ConstantExpression] filter
        def initialize(node, filter, arguments, lineno)
          if filter.is_a?(Filter)
            name = filter.name
            filter_name = ConstantExpression.new(name, lineno)
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
            type: 'filter'
          }, lineno)

          if filter.is_a?(Filter)
            attributes[:twig_callable] = filter
          end
        end

        def compile(compiler)
          name = node(:filter).attributes[:value]

          if name != attributes[:name]
            raise 'Changing the value of a "filter" node is not supported'
          end

          if name == "raw"
            raise 'Cannot create raw filter via FilterExpression'
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
