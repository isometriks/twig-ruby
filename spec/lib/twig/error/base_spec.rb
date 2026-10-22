# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Error::Base do
  let(:source) { Twig::Source.new('', 'broken.html') }

  it 'keeps the last character of a message without punctuation' do
    error = Twig::Error::Syntax.new('boom', 2, source)

    expect(error.message).to eq('boom in "broken.html" at line 2')
  end

  it 'moves a trailing period after the location' do
    error = Twig::Error::Syntax.new('Done.', 2, source)

    expect(error.message).to eq('Done in "broken.html" at line 2.')
  end

  it 'moves a trailing question mark after the location' do
    error = Twig::Error::Syntax.new('What?', 2, source)

    expect(error.message).to eq('What in "broken.html" at line 2?')
  end

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
