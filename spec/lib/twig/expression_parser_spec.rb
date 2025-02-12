# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

module Twig
  RSpec.describe ExpressionParser do
    context 'operators of difference precedence' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ 1 + 2 * 3 }}
            {{ 2 * 3 + 1 }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            7
            7
          OUTPUTS
        end
      end
    end

    context 'recognizes null as a keyword' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ null }}
            {{ NULL }}
            {{ nil }}
          INPUTS
        end

        let(:outputs) do
          [
            '',
            '',
            '',
          ]
        end
      end
    end

    context 'parses sequence expressions' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ names[0] }}
            {{ math[0] + math[1] }}
            {{ math[0] == math[1] ? "OK" : "KO" }}
            {{ ["Hello", "World!"][0] }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            Craig
            3
            KO
            Hello
          OUTPUTS
        end

        let(:locals) { { math: [1, 2], names: %w[Craig Bob] } }
      end
    end

    context 'parses mapping expressions' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ { hello: "Hello", world: "World!" }["hello"] }}
            {{ names["first"] }} {{ names["last"] }}
            {{ names[:first] }} {{ names[:last] }}
            {{ { hello: :world }[:hello] }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            Hello
            Hello World!
            Hello World!
            world
          OUTPUTS
        end

        let(:locals) { { names: { first: 'Hello', last: 'World!' } } }
      end
    end

    context 'with class variable in call context' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ @greeting }}
            {{ @greeting_array[0] }} {{ @greeting_array[1] }}
            {{ @greeting_array.join(" ") }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            Hello World!
            Hello World!
            Hello World!
          OUTPUTS
        end

        let(:call_context) do
          Class.new do
            def initialize
              @greeting = 'Hello World!'
              @greeting_array = %w[Hello World!]
            end
          end.new
        end
      end
    end

    context 'with arrow function' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          <<~INPUTS
            {{ [1, 2]|map(n => n * 2) }}
          INPUTS
        end

        let(:outputs) do
          <<~OUTPUTS
            [2, 4]
          OUTPUTS
        end
      end
    end

    context 'with multiline strings' do
      it_behaves_like 'render_and_assert' do
        let(:inputs) do
          [
            '{{ "Hello " ~
                 # Stopping by for a comment
               "World!" }}',
          ]
        end

        let(:outputs) do
          ['Hello World!']
        end
      end
    end
  end
end
