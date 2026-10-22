# frozen_string_literal: true

module Twig
  module ExpressionParser
    module Prefix
      # Sequences, mappings and call arguments parse the spread operator themselves; it is
      # invalid anywhere else. Registering it keeps "..." an operator token for the lexer.
      class Spread < PrefixExpressionParser
        def parse(parser, token)
          raise Error::Syntax.new(
            'The spread operator can only be used on sequence elements, mapping elements, and call arguments.',
            token.lineno,
            parser.stream.source
          )
        end

        def name
          '...'
        end

        def description
          'Spread operator'
        end

        def precedence
          512
        end
      end
    end
  end
end
