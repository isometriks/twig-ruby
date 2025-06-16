# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Template do
  let(:template) { described_class.new(double(Twig::Environment)) }

  context 'when a block is missing' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ block("missing") }}' }
      let(:error) { Twig::Error::Runtime }
      let(:message) { /Block "missing" on template/ }
    end
  end

  context do
    before do
      allow(template).to receive(:source_context).and_return(
        double(Twig::Source, {
          name: 'test.twig',
          path: '/test.twig',
        })
      )
    end

    it 'requires a context to render' do
      expect { template.render({}) }.to raise_error(
        Twig::Error::Runtime,
        /Render must implement Twig::Runtime::Context/
      )
    end
  end
end
