# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

module Twig
  module Node
    module Expression
      RSpec.describe Hash do
        let(:node) { described_class.new({}, 0) }

        it 'adds elements to the node with keys' do
          node.add_element(
            Constant.new('value', 0),
            Constant.new('key', 1)
          )

          expect(node.nodes.length).to eq(2)

          values = node.nodes.values.map { |node| node.attributes[:value] }

          expect(values).to eq(%w[key value])
        end

        it 'adds elements to the node without keys' do
          node.add_element(
            Constant.new('value', 0)
          )

          expect(node.nodes.length).to eq(2)

          values = node.nodes.values.map { |node| node.attributes[:value] }

          expect(values).to eq([0, 'value'])
        end

        describe 'dynamic keys' do
          let(:stringable) do
            Class.new do
              def to_s
                'ctx_obj'
              end
            end.new
          end

          it_behaves_like 'render_and_assert' do
            let(:locals) { { obj: stringable, holder: { 'obj' => stringable }, number: 4, nothing: nil } }
            let(:inputs) do
              [
                "{{ {(obj): 'a'}['ctx_obj'] }}",
                "{{ {(holder.obj): 'a'}['ctx_obj'] }}",
                "{{ {(obj|raw): 'a'}['ctx_obj'] }}",
                "{{ {(number): 'a'}|keys|first is same as(4) ? 'int' : 'string' }}",
                "{{ {(2 + 2): 'a'}|keys|first is same as(4) ? 'int' : 'string' }}",
                "{{ {(nothing): 'a'}|keys|first is same as('') ? 'empty' : 'other' }}",
                "{{ {('a' ~ 'b'): 'a'}|keys|first }}",
              ]
            end
            let(:outputs) { %w[a a a int int empty ab] }
          end

          it_behaves_like 'render_and_assert' do
            let(:locals) { { number: 5, id: '5' } }
            let(:inputs) do
              [
                '{% set m = {(number): "five"} %}{{ m[5] }}|{{ m["5"] }}|{{ m[id] }}',
                '{{ {5: "five"}["5"] }}|{{ {"5": "five"}[5] }}',
                '{{ {5: "five"}["05"] is defined ? "found" : "missing" }}',
              ]
            end
            let(:outputs) { %w[five|five|five five|five missing] }
          end
        end
      end
    end
  end
end
