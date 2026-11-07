# frozen_string_literal: true

require 'spec_helper'

# Twig's messages end in a period, which goes after the template and line
RSpec.describe Twig::Error::Base do
  {
    '{% set a, b = 1 %}' => [
      Twig::Error::Syntax,
      'When using set, you must have the same number of variables and assignments in "index" at line 1.',
    ],
    '{% set a, b %}x{% endset %}' => [
      Twig::Error::Syntax,
      'When using set with a block, you cannot have a multi-target in "index" at line 1.',
    ],
    '{{ "x"(1) }}' => [
      Twig::Error::Syntax,
      'Function name must be an identifier in "index" at line 1.',
    ],
    "{{ 1.5|round(0, 'xx') }}" => [
      Twig::Error::Runtime,
      'The "round" filter only supports the "common", "ceil", and "floor" methods in "index" at line 1.',
    ],
  }.each do |template, (error, message)|
    it "ends the message for #{template} with a period" do
      environment = Twig::Environment.new(Twig::Loader::Hash.new('index' => template))

      expect { environment.load('index').render }.to raise_error(error, message)
    end
  end
end
