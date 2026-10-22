# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class ObjectDestructuringSetBinary < Binary::Base
          def initialize(left, right, lineno)
            @mappings = []

            left.key_value_pairs.each do |key, value|
              unless value.is_a?(Variable::Context)
                raise Error::Syntax.new(
                  "Cannot assign to \"#{value.class}\", only variables can be assigned in " \
                  'object/mapping destructuring.',
                  lineno
                )
              end

              @mappings << {
                property: key.attributes[:value],
                variable: value.attributes[:name],
              }
            end

            super
          end

          def compile(compiler)
            compiler.add_debug_info(self)

            @mappings.each_with_index do |mapping, i|
              compiler.raw(', ') if i.positive?
              compiler.raw('context[').string(mapping[:variable]).raw(']')
            end

            compiler.raw(' = ')

            @mappings.each_with_index do |mapping, i|
              compiler.raw(', ') if i.positive?
              compiler.
                raw('::Twig::Extension::Core.get_attribute(env, source_context, ').
                subcompile(nodes[:right]).
                raw(', ').
                repr(mapping[:property]).
                raw(', ').
                repr(Template::ANY_CALL).
                raw(', lineno: ').
                repr(nodes[:right].lineno).
                raw(')')
            end
          end

          def operator(compiler)
            compiler.raw('=')
          end
        end
      end
    end
  end
end
