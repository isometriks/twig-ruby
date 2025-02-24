# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module SupportDefinedTest
        def enable_defined_test
          self.defined_test = true
        end

        def define_test_enabled?
          defined_test
        end

        private

        # @param [Boolean] defined_test
        # @return [Boolean]
        attr_accessor :defined_test
      end
    end
  end
end
