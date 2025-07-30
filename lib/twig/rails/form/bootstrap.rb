module Twig
  module Rails
    module Form
      class Bootstrap < Twig
        def input_group(&)
          twig_template.render_block('input_group', { blocked: -> { yield } })
        end

        private

        def template_name
          'form/bootstrap.html.twig'
        end
      end
    end
  end
end
