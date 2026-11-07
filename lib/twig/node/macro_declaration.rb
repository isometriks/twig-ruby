# frozen_string_literal: true

module Twig
  module Node
    # Where a macro is declared in the template body. The macro itself is kept in the
    # module's macros; this node only lets the "macro" tag be checked like the other
    # tags that may only be used at the root of a template.
    class MacroDeclaration < Node::Config
      # @param [String] name
      # @param [Integer] lineno
      def initialize(name, lineno)
        super(lineno)

        attributes[:name] = name
      end
    end
  end
end
