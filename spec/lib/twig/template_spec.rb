# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Template do
  context 'when a block is missing' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ block("missing") }}' }
      let(:error) { Twig::Error::Runtime }
      let(:message) { /Block 'missing' on template/ }
    end
  end
end
