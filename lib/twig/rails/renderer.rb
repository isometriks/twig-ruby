# frozen_string_literal: true

module Twig
  module Rails
    class Renderer
      def call(template, source)
        <<~TEMPLATE
          ::Twig.
            environment.
            load("#{template.short_identifier}").
            render(
              local_assigns,
              call_context: self,
              output_buffer: @output_buffer
            )

          @output_buffer
        TEMPLATE
      end

      def translate_location(spot, _backtrace_location, source)
        exception = $ERROR_INFO

        return nil unless exception.is_a?(::ActionView::Template::Error)

        twig_exception = exception.cause

        return nil unless twig_exception.is_a?(::Twig::Error::Base)

        lineno = twig_exception.lineno
        lineno = 1 if lineno == -1

        spot[:script_lines] = twig_exception.source_context&.code&.lines || source.lines
        spot[:first_lineno] = spot[:last_lineno] = lineno
        spot[:first_column] = spot[:last_column] = 0

        spot
      end
    end
  end
end
