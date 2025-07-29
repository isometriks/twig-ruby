module Twig
  module Rails
    module Form
      class Twig < ActionView::Helpers::FormBuilder
        def self._to_partial_path
          'form'
        end

        field_helpers.each do |field|
          define_method(:"#{field}") do |name, options = {}|
            if twig_template.block?(field, {})
              twig_template.render_block(
                field,
                {
                  template: @template,
                  object_name: @object_name,
                  name:,
                  options:,
                }
              )
            else
              super(name, options)
            end
          end
        end

        def row(name, field, options = {})
          label_options = options.except(:field).merge(options.fetch(:label, {}))
          field_options = options.except(:label).merge(options.fetch(:field, {}))
          row_template = twig_template.block?("row_#{field}") ? "row_#{field}" : 'row'

          twig_template.render_block(
            row_template,
            {
              template: @template,
              object_name: @object_name,
              name:,
              options:,
              label: self.label(name, label_options),
              field: self.send(field, name, field_options),
            }
          )
        end

        private

        def filter_options(options = {})
          options
        end

        def template_name
          'form/theme.html.twig'
        end

        def twig_template
          ::Twig.environment.load(template_name)
        end
      end
    end
  end
end
