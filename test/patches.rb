# frozen_string_literal: true

module Twig
  module Parity
    def self.print(value)
      case value
      when TrueClass
        '1'
      when FalseClass
        ''
      else
        value
      end
    end

    module Runtime
      class Loader < RuntimeLoader::Base
        def initialize(environment)
          super()

          @environment = environment
        end

        def load(name)
          Escaper.new(@environment.charset)
        end
      end

      class Escaper < Twig::Runtime::Escaper
        def escape(string, strategy = :html, charset = nil, autoescape = false)
          # return "#{string} - #{string.class.name}"
          case string
          when TrueClass
            '1'
          when FalseClass
            ''
          else
            super
          end
        end
      end
    end
  end

  module Node
    class Print
      def compile(compiler)
        compiler.
          add_debug_info(self).
          write('context.output_buffer.append = ').
          raw('::Twig::Parity.print(').
          subcompile(nodes[:expr]).
          raw(");\n")
      end
    end
  end
end
