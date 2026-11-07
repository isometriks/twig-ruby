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

  it 'reports the column after the line' do
    error = Twig::Error::Syntax.new('Done.', 2, source, column: 5)

    expect(error.message).to eq('Done in "broken.html" at line 2 column 5.')
  end

  it 'reports no column without a line' do
    error = Twig::Error::Syntax.new('Done.', -1, source, column: 5)

    expect(error.message).to eq('Done in "broken.html".')
  end

  it 'updates the message when the column changes' do
    error = Twig::Error::Syntax.new('Done.', 2, source)
    error.column = 3

    expect(error.message).to eq('Done in "broken.html" at line 2 column 3.')
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

RSpec.describe 'The line of a runtime error' do
  let(:view) do
    Class.new do
      def boom
        raise 'kaboom'
      end
    end.new
  end

  let(:templates) do
    {
      'local' => "{% macro m() %}\n\n{{ boom }}\n{% endmacro %}\n\n\n\n{{ _self.m() }}\n",
      'importer' => "{% import 'macros' as x %}\n\n\n\n\n\n\n{{ x.m() }}\n",
      'macros' => "{% macro m() %}\n\n{{ boom }}\n{% endmacro %}\n",
      'nested' => "{% macro inner() %}\n{{ boom }}\n{% endmacro %}\n{% macro m() %}\n\n{{ _self.inner() }}\n" \
                  "{% endmacro %}\n{{ _self.m() }}\n",
      'apply' => "{% apply upper %}\n\n{{ boom }}\n{% endapply %}\n",
      'block' => "{% block b %}\n{% for i in [1] %}\n\n{{ boom }}\n{% endfor %}\n{% endblock %}\n",
      'child' => "{% extends 'parent' %}\n{% block b %}\n\n{{ boom }}\n{% endblock %}\n",
      'parent' => "{% block b %}{% endblock %}\n",
    }
  end

  {
    'local' => 'in "local" at line 3.',
    'importer' => 'in "importer" at line 8.',
    'nested' => 'in "nested" at line 2.',
    'apply' => 'in "apply" at line 3.',
    'block' => 'in "block" at line 4.',
    'child' => 'in "child" at line 4.',
  }.each do |name, location|
    it "is the line that raised in #{name}" do
      environment = Twig::Environment.new(Twig::Loader::Hash.new(templates))

      expect { environment.load(name).render({}, call_context: view) }.
        to raise_error(
          Twig::Error::Runtime,
          %(An exception has been thrown during the rendering of a template ("kaboom") #{location})
        )
    end
  end
end
