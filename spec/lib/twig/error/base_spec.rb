# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Error::Base do
  describe '#guess' do
    it 'skips frames from a template class a recompile has since replaced' do
      error = described_class.new('Oops')
      location = instance_double(Thread::Backtrace::Location, label: 'Twig::Compiled::Template_gone#call', lineno: 3)
      allow(error).to receive(:backtrace_locations).and_return([location])

      expect { error.guess }.not_to raise_error
      expect(error.lineno).to eq(-1)
    end
  end
end
