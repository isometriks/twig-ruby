# frozen_string_literal: true

module Twig
  module TokenParser
    # Imports macros.
    #
    # {% import 'forms.html.twig' as forms %}
    #
    class Import < Base
      def parse(token)
        macro = parser.parse_expression
        parser.stream.expect(Token::NAME_TYPE, 'as')
        name = parser.stream.expect(Token::NAME_TYPE).value
        var = Node::Expression::Variable::AssignTemplate.new(
          Node::Expression::Variable::Template.new(name, token.lineno),
          global: parser.main_scope?
        )
        parser.stream.expect(Token::BLOCK_END_TYPE)
        parser.add_imported_symbol(:template, name)

        Node::Import.new(macro, var, token.lineno)
      end

      def tag
        'import'
      end
    end
  end
end
