# frozen_string_literal: true

module Twig
  module TokenParser
    # Imports macros.
    #
    # {% from 'forms.html.twig' import forms %}
    #
    class From < Base
      # @param [Token] token
      def parse(token)
        macro = parser.parse_expression
        stream = parser.stream
        stream.expect(Token::NAME_TYPE, 'import')

        targets = {}
        loop do
          name = stream.expect(Token::NAME_TYPE).value

          aliased = if stream.next_if('as')
                      Node::Expression::Variable::AssignContext.new(
                        stream.expect(Token::NAME_TYPE).value,
                        token.lineno
                      )
                    else
                      Node::Expression::Variable::AssignContext.new(name, token.lineno)
                    end

          targets[name] = aliased

          unless stream.next_if(Token::PUNCTUATION_TYPE, ',')
            break
          end
        end

        stream.expect(Token::BLOCK_END_TYPE)

        internal_ref = Node::Expression::Variable::AssignTemplate.new(
          Node::Expression::Variable::Template.new(nil, token.lineno),
          global: parser.main_scope?
        )

        node = Node::Import.new(macro, internal_ref, token.lineno)

        targets.each do |name, aliased|
          parser.add_imported_symbol(:function, aliased.attributes[:name], "macro_#{name}", internal_ref)
        end

        node
      end

      def tag
        'from'
      end
    end
  end
end
