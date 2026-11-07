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
        def escape(string, strategy = :html, charset: nil, autoescape: false)
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

module Twig
  module Parity
    # Collects the deprecations Twig reports, as IntegrationTestCase does with
    # an error handler for E_USER_DEPRECATED
    module Deprecations
      class << self
        # @param [Array<String>] into
        def capture(into)
          previous = @captured
          @captured = into

          yield
        ensure
          @captured = previous
        end

        # @return [Boolean] whether a capture took the message
        def record(message)
          return false if @captured.nil?

          @captured << message
          true
        end
      end
    end
  end

  module Extension
    class Core
      class << self
        prepend(Module.new do
          def report_deprecation(message)
            super unless ::Twig::Parity::Deprecations.record(message)
          end
        end)
      end
    end
  end
end
