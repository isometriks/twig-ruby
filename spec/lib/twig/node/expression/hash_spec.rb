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
      end
    end
  end
end
