# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Cache do
  # Rails would normally swap buffers during capture, but if
  it_behaves_like 'render_and_assert' do
    let(:output_buffer) do
      Class.new(Twig::OutputBuffer) do
        def capture(&)
          @buffer, old_buffer = +'', @buffer
          yield
          @buffer
        ensure
          @buffer = old_buffer
        end
      end.new
    end

    let(:extensions) { [Twig::Extension::Rails.new] }
    let(:inputs) do
      <<~INPUTS
        {% cache(:something) %}Hello World!{% endcache %}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        --Hello World!--
      OUTPUTS
    end

    let(:call_context) do
      Class.new do
        def initialize(buffer)
          @buffer = buffer
        end

        def capture(&)
          captured = @buffer.capture(&)

          "--#{captured}--"
        end

        def cache(...)
          yield
        end
      end.new(output_buffer)
    end
  end
end
