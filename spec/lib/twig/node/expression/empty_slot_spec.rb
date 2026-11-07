# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::EmptySlot do
  context 'when used outside of destructuring' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ [, 1] }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /Empty array elements are only allowed in destructuring assignments/ }
    end
  end
end
